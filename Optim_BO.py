import numpy as np
import subprocess
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.optimize import minimize
from scipy.stats import norm
# =================== SCALE LEN FUNCTION ===================
def nll_func(X_train, Y_train, Noise_Vars_train):
    Y_mean = np.mean(Y_train)
    Y_centered = Y_train - Y_mean

    
    def nll(theta):
        length_scale = theta[0]
        K = cov(X_train,X_train, length_scale) + np.diag(Noise_Vars_train.flatten())

        sign, logdet = np.linalg.slogdet(K)
        if sign<=0: return np.inf

        K_inv = np.linalg.inv(K)

        data_fit=0.5*Y_centered.T.dot(K_inv).dot(Y_centered)[0,0]
        complexity = 0.5*logdet
        constant =0.5*len(X_train)*np.log(2*np.pi)

        return data_fit+complexity+constant
    return nll
# ===========================================================


# ==================== MODEL PARAMETERS ======================

targetName='W'
thickness_bounds=[1.0, 7.0]
initPoints=6
testPoints=12
os.makedirs("./graphs", exist_ok=True)


# ============================================================

# ==================== PHITS FUNCTIONS =======================
def parse_PHITS(workdir):
    file_path = os.path.join(".", workdir, "particle_flux_in_box.out")

    if not os.path.exists(file_path):
        print(f"[ ERROR ]: FILE NOT FOUND  {file_path}")
        return 0.0, 1.0
        
    neutron_flux = 0.0
    neutron_flux_err = 1.0

    with open(file_path, 'r') as file:
        for line in file:
            if "sum over" in line:
                parts = line.split()

                try:
                    neutron_flux = float(parts[6])
                    neutron_flux_err = float(parts[7])
                    break
                except (IndexError, ValueError):
                    print(f"[ ERROR ]: PARSE FAILURE ")
                    break
    return neutron_flux, neutron_flux_err

def ObjectiveFunction(x, fidelity='low'):

    target_thickness = float(np.ravel(x)[0])
    target_thickness_str = f"{target_thickness:.4f}"

    print(f"-> PHITS START: THICKNESS = {target_thickness_str} cm | MODE = {fidelity}")
    
    if fidelity=='low':
        cost=1
    else:
        cost=20

    script_path = "./run1D.sh"
    try:
        subprocess.run([script_path, target_thickness_str, fidelity], check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"[ ERROR ]:\n{e.stderr}")
        return 0.0, 1e6, cost
    
    workdir = f"./results/{targetName}_{target_thickness_str}"
    
    y_result, y_err = parse_PHITS(workdir=workdir)

    print(f"[ INFO ]: PHITS DONE : thickness= {target_thickness_str} cm | FLUX= {y_result:.4f} | ERR= {y_err:.4f}")
    with open("output.txt", "a") as f:
        f.write(f"{target_thickness_str}\t{y_result:.4f}\t{y_err:.4f}\n")
    std_dev = y_err * np.abs(y_result)
    variance = std_dev**2

    return y_result, variance, cost
# ===========================================================

# ====================== BAYES OPTIM ========================
def cov(x1, x2, scale_len):
    d=np.abs(x1-x2.T)/scale_len
    sqrt5_d = np.sqrt(5)*d

    return (1.0+sqrt5_d+(5.0/3.0)*d**2)*np.exp(-sqrt5_d)

def gaussian_process(X_train, Y_train, Noise_Vars_train, X_test, scale_len):
    Y_mean = np.mean(Y_train)
    Y_centered = Y_train - Y_mean
    
    K = cov(X_train, X_train, scale_len)+np.diag(Noise_Vars_train.flatten())

    K_s=cov(X_train, X_test, scale_len)
    K_ss=cov(X_test,X_test, scale_len)

    K_inv = np.linalg.inv(K)

    mu_TEST = K_s.T.dot(K_inv).dot(Y_centered) + Y_mean
    cov_TEST = K_ss - K_s.T.dot(K_inv).dot(K_s)

    return mu_TEST, np.sqrt(np.diag(cov_TEST).reshape(-1,1))

def UCB(mu, std, kappa=2.0):
    return mu +kappa*std

def EI(mu, std, best_y, xi=0.01):
    Z = np.zeros_like(mu)
    ei = np.zeros_like(mu)

    mask = std>0

    if np.any(mask):
        Z[mask]=(mu[mask]-best_y-xi)/std[mask]
        ei[mask]=(mu[mask]-best_y-xi)*norm.cdf(Z[mask])+std[mask]*norm.pdf(Z[mask])

    return ei

# =======================================================

X_train = np.linspace(thickness_bounds[0], thickness_bounds[1], initPoints).reshape(-1,1)
Y_train_list = []
Err_list = []
Colors_list = []

print("[ INFO ]: COMPUTING INIT POINTS...")

with open("output.txt", "w") as f:
    f.write("Thickness_cm\tFlux\t\tError_rel\n")

for x_point in X_train:
    y_result, var, _ = ObjectiveFunction(x_point, fidelity='low')
    Y_train_list.append([y_result])
    Err_list.append([var])
    Colors_list.append('orange')



Y_train=np.array(Y_train_list)
Noise_Vars_train=np.array(Err_list)

X_grid=np.linspace(thickness_bounds[0], thickness_bounds[1],1000).reshape(-1,1)

print("[ INFO ]: OPTIM START...\n")
np.random.seed(42)


for i in range(testPoints):

    nll_fn = nll_func(X_train, Y_train, Noise_Vars_train)

    res = minimize(nll_fn, [0.2], bounds=[(0.01, 10.0)], method='L-BFGS-B')
    opt_scale_len = res.x[0]
    mu, std = gaussian_process(X_train, Y_train, Noise_Vars_train, X_grid, opt_scale_len)
    
    #ucb = UCB(mu,std)
    #best_idx=np.argmax(ucb)

    current_best_y = np.max(mu)
    ei=EI(mu,std,current_best_y)
    best_idx=np.argmax(ei)

    next_X= X_grid[best_idx].reshape(-1,1)
    uncertainty_at_next_X=std[best_idx][0]

    expected_relative_error = uncertainty_at_next_X / (np.abs(mu[best_idx][0]) + 1e-9)
    
    if expected_relative_error > 0.015:
        chosen_fidelity = 'low'
        marker_color = 'orange'
    else:
        chosen_fidelity = 'high'
        marker_color = 'red'

    Colors_list.append(marker_color)

    plt.figure(figsize=(10,5))
    plt.subplot(1, 2, 1)
    plt.title(f"Iteration {i}  |  scale_len = {opt_scale_len:.8f}")
    plt.plot(X_grid,mu,'b-', label="mu(x)")
    plt.fill_between(X_grid.flatten(), (mu - 2*std).flatten(), (mu + 2*std).flatten(), alpha=0.2, color='blue', label='uncertainty')
    
    for j in range(len(X_train)):
        lbl = 'PHITS OUTPUT' if j == 0 else None
        plt.errorbar(X_train[j][0], Y_train[j][0], yerr=np.sqrt(Noise_Vars_train[j][0]), fmt='o', color=Colors_list[j], label=lbl)

    plt.legend(loc="lower left", fontsize='small')

    plt.subplot(1, 2, 2)
    plt.title("Acquisition function (EI)")
    plt.plot(X_grid, ei, 'g-', label='EI')
    
    plt.axvline(next_X, color='r', linestyle='--', label=f'Next Point: {next_X[0][0]:.2f}')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(f"./graphs/iteration_{i}.png", dpi=300)
    
    next_Y, next_Noise, cost=ObjectiveFunction(next_X, fidelity=chosen_fidelity)

    X_train=np.vstack([X_train, next_X])
    Y_train=np.vstack([Y_train, next_Y])
    Noise_Vars_train = np.vstack([Noise_Vars_train, next_Noise])

    print(f"Iteration {i}, x= {next_X[0][0]:.3f}, y={next_Y[0][0]:.3f} | fidelity={chosen_fidelity} | uncert = {uncertainty_at_next_X:.3f}")
    plt.close()

best_idx_total = np.argmax(Y_train)
print(f"x_max = {X_train[best_idx_total][0]:.3f}, y_max = {Y_train[best_idx_total][0]:.3f}")