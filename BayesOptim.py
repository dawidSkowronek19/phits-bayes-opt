import numpy as np

import matplotlib.pyplot as plt
from scipy.optimize import minimize
from scipy.stats import norm

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

def analitic_function(x):
    return -((6.0*x-2)**2 * np.sin(12*x-4))

def ObjectiveFunction(x, fidelity='low'):
    
    if fidelity=='low':
        relative_error=0.3
        cost=1
    else:
        relative_error=0.01
        cost=20

    

    true_y = analitic_function(x)
    std_dev=relative_error*(np.abs(true_y)+1e-3)

    noisy_y=true_y+np.random.normal(0, std_dev)
    variance =std_dev**2

    return noisy_y, variance, cost

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



X_train = np.array([[0.1], [0.3], [0.5], [0.7], [0.9]])


X_grid=np.linspace(0,1,1000).reshape(-1,1)

print("Rozpoczynam optymalizację...\n")
np.random.seed(42)
Y_train, Noise_Vars_train, _ = ObjectiveFunction(X_train)

for i in range(10):

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
    
    if uncertainty_at_next_X>0.8:
        chosen_fidelity='low'
        marker_color='orange'
    else:
        chosen_fidelity='high'
        marker_color='red'

    plt.figure(figsize=(10,5))
    plt.subplot(1, 2, 1)
    plt.title(f"Iteracja {i}  |  scale_len = {opt_scale_len:.8f}")

    plt.plot(X_grid, analitic_function(X_grid), 'k--', label="Prawdziwa funkcja")
    plt.plot(X_grid,mu,'b-', label="mu(x)")
    plt.fill_between(X_grid.flatten(), (mu - 2*std).flatten(), (mu + 2*std).flatten(), alpha=0.2, color='blue', label='Niepewność')
    plt.errorbar(X_train.flatten(), Y_train.flatten(), yerr=np.sqrt(Noise_Vars_train).flatten(), fmt='o', color=marker_color, label='Pomiary MC')
    #plt.ylim(-0.5, 0.2)
    plt.legend(loc="lower left", fontsize='small')

    plt.subplot(1, 2, 2)
    plt.title("Funkcja Akwizycji (EI)")
    plt.plot(X_grid, ei, 'g-', label='EI')
    
    plt.axvline(next_X, color='r', linestyle='--', label=f'Następny punkt: {next_X[0][0]:.2f}')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(f"./graphs/iteration_{i}.png")
    
    next_Y, next_Noise, cost=ObjectiveFunction(next_X, fidelity=chosen_fidelity)

    X_train=np.vstack([X_train, next_X])
    Y_train=np.vstack([Y_train, next_Y])
    Noise_Vars_train = np.vstack([Noise_Vars_train, next_Noise])

    print(f"Iteracja {i}, x= {next_X[0][0]:.3f}, y={next_Y[0][0]:.3f} | fidelity={chosen_fidelity} | uncert = {uncertainty_at_next_X:.3f}")

best_idx_total = np.argmax(Y_train)
print(f"x_max = {X_train[best_idx_total][0]:.3f}, y_max = {Y_train[best_idx_total][0]:.3f}")