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

N_high = 250000 #maxcas * maxbch
N_low = 40000

threshold_distance=0.05

normalization_const=1e12


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

    script_path = "./run1D.sh"
    try:
        subprocess.run([script_path, target_thickness_str, fidelity], check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"[ ERROR ]:\n{e.stderr}")
        return 0.0, 1e6
    
    workdir = f"./results/{targetName}_{target_thickness_str}"
    
    y_result, y_err = parse_PHITS(workdir=workdir)

    print(f"[ INFO ]: PHITS DONE : thickness= {target_thickness_str} cm | FLUX= {y_result:.4f} | ERR= {y_err:.4f}")
    with open("output.txt", "a") as f:
        f.write(f"{target_thickness_str}\t{y_result:.4f}\t{y_err:.4f}\n")
    std_dev = y_err * np.abs(y_result)
    variance = std_dev**2

    return y_result, variance
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


# ========================== RESTART ====================


def register_after_rest(filepath="output.txt"):

    if not os.path.exists(filepath) : return None, None, None

    X_loaded, Y_loaded, Err_loaded = [], [], []
    try: 
        with open(filepath, 'r') as f:
            header=f.readline()
            for line in f:
                parts = line.strip().split()
                
                if (len(parts)>=3):
                    x_val = float(parts[0])
                    y_val = float(parts[1])
                    err_rel = float(parts[2])

                    X_loaded.append([x_val])
                    Y_loaded.append([y_val])

                    std_dev = err_rel * np.abs(y_val)
                    Err_loaded.append([std_dev**2])

        if len(X_loaded)>0: 
            return np.array(X_loaded), np.array(Y_loaded), np.array(Err_loaded)
    except Exception as e:
        print(f"[ ERROR ] Reading {filepath} failure")
    
    return None, None, None

# =======================================================

# ===================== INIT =============================
print("[ INFO ]: CHECKING RESTART DATA...")
X_train, Y_train, Noise_Vars_train = register_after_rest("output.txt")
Colors_list = []

if X_train is not None:
    print(f"[ INFO ]: # Restart Points = {len(X_train)}")
    Colors_list = ['blue']*len(X_train)
else:
    print(f"[ INFO ]: NO HISTORY TO READ, COMPUTING INIT POINTS")

    X_train = np.linspace(thickness_bounds[0], thickness_bounds[1], initPoints).reshape(-1,1)
    Y_train_list = []
    Err_list = []


    with open("output.txt", "w") as f:
        f.write("Thickness_cm\tFlux\t\tError_rel\n")

    for x_point in X_train:
        y_result, var = ObjectiveFunction(x_point, fidelity='low')
        Y_train_list.append([y_result])
        Err_list.append([var])
        Colors_list.append('orange')



    Y_train=np.array(Y_train_list)
    Noise_Vars_train=np.array(Err_list)

X_grid=np.linspace(thickness_bounds[0], thickness_bounds[1],1000).reshape(-1,1)
# ========================================================

# ==================== OPTIMALIZATION PROCESS ===================
print("[ INFO ]: OPTIM START...\n")
np.random.seed(42)

target_total_points = initPoints + testPoints
current_points = len(X_train)
remaining_iterations = max(0, target_total_points - current_points)

for i in range(remaining_iterations):
    actual_iter = current_points + i - initPoints
    

    Y_train_sc = Y_train/normalization_const
    Noise_Vars_train_sc = Noise_Vars_train/(normalization_const**2)

    nll_fn = nll_func(X_train, Y_train_sc, Noise_Vars_train_sc)

    res = minimize(nll_fn, [0.2], bounds=[(0.01, 10.0)], method='L-BFGS-B')
    opt_scale_len = res.x[0]
    mu_sc, std_sc = gaussian_process(X_train, Y_train_sc, Noise_Vars_train_sc, X_grid, opt_scale_len)

    mu_train_sc, _ = gaussian_process(X_train, Y_train_sc, Noise_Vars_train_sc, X_train, opt_scale_len)
    current_best_y_sc = np.max(mu_train_sc)
    

    #========= FOR MODE SELECTION ==========
    ei = EI(mu_sc, std_sc, current_best_y_sc)
    best_idx=np.argmax(ei)
    next_X=X_grid[best_idx].reshape(-1,1)

    mu=mu_sc*normalization_const
    std=std_sc*normalization_const
    uncertainty_at_next_X = std[best_idx][0]

    dist_to_closestX = np.min(np.abs(X_train-next_X))
    



    
    
    if dist_to_closestX <threshold_distance:
        chosen_fidelity = 'high'
        marker_color = 'red'
    else:
        chosen_fidelity = 'low'
        marker_color = 'orange'


    next_Y, next_Noise=ObjectiveFunction(next_X, fidelity=chosen_fidelity)
    Colors_list.append(marker_color)
    X_train=np.vstack([X_train, next_X])
    Y_train=np.vstack([Y_train, [[next_Y]]])
    Noise_Vars_train = np.vstack([Noise_Vars_train, [[next_Noise]]])

    plt.figure(figsize=(10,5))
    plt.subplot(1, 2, 1)
    plt.title(f"Iteration {actual_iter}  |  scale_len = {opt_scale_len:.8f}")
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
    plt.savefig(f"./graphs/iteration_{actual_iter}.png", dpi=300)
    

   #print(f"Iteration {i}, x= {next_X[0][0]:.3f}, y={next_Y[0][0]:.3f} | fidelity={chosen_fidelity} | uncert = {uncertainty_at_next_X:.3f}")
    plt.close()

best_idx_total = np.argmax(Y_train)
print(f"x_max = {X_train[best_idx_total][0]:.3f}, y_max = {Y_train[best_idx_total][0]:.3f}")