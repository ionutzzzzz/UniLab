import numpy as np

def pid_tuning(K=1.0, T=1.0, L=0.1, method='ziegler-nichols'):
    """
    Tuning of PID parameters based on Plant dynamics parameters:
    - K: plant static gain
    - T: plant time constant
    - L: plant dead time/delay
    """
    K = float(K)
    T = float(T)
    L = float(L)
    
    if L <= 0:
        L = 0.001  # Guard against division by zero
        
    Kp, Ki, Kd = 0.0, 0.0, 0.0
    
    if method.lower() == 'ziegler-nichols':
        # Ziegler-Nichols open-loop tuning rule
        a = K * L / T
        Kp = 1.2 / a
        Ti = 2.0 * L
        Td = 0.5 * L
        Ki = Kp / Ti
        Kd = Kp * Td
    else:
        # Cohen-Coon method
        r = L / T
        Kp = (1 / K) * (1.35 / r + 0.25)
        Ti = L * (2.5 + 0.5 * r) / (1 + 0.6 * r)
        Td = 0.37 * L / (1 + 0.2 * r)
        Ki = Kp / Ti
        Kd = Kp * Td
        
    return {
        'Kp': Kp,
        'Ki': Ki,
        'Kd': Kd,
        'parameters': {'gain': K, 'time_constant': T, 'delay': L, 'method': method}
    }

def finite_difference_1d(length=1.0, conductivity=50.0, boundary_temps=(100.0, 20.0), source_term=0.0, n_points=50):
    """
    Solves 1D steady-state heat equation: -k * d^2T/dx^2 = Q
    - length: length of the rod (meters)
    - conductivity: thermal conductivity (W/mK)
    - boundary_temps: tuple of (T_left, T_right) (Celsius/Kelvin)
    - source_term: constant heat generation rate Q (W/m^3)
    - n_points: number of grid points
    """
    L = float(length)
    k = float(conductivity)
    T_left, T_right = float(boundary_temps[0]), float(boundary_temps[1])
    Q = float(source_term)
    N = int(n_points)
    
    dx = L / (N - 1)
    x = np.linspace(0, L, N)
    
    # Construct tridiagonal system A * T = B
    A = np.zeros((N, N))
    B = np.zeros(N)
    
    # Boundary conditions
    A[0, 0] = 1.0
    B[0] = T_left
    
    A[-1, -1] = 1.0
    B[-1] = T_right
    
    # Interior points
    for i in range(1, N - 1):
        A[i, i - 1] = 1.0
        A[i, i] = -2.0
        A[i, i + 1] = 1.0
        B[i] = -Q * (dx ** 2) / k
        
    T = np.linalg.solve(A, B)
    return x.tolist(), T.tolist()

def beam_stress(length=5.0, load=1000.0, E=200e9, I=1e-5, n_points=100):
    """
    Calculates deflection and bending moment of a Cantilever Beam under a point load at the free end.
    - length: length of beam (m)
    - load: load at free end (N)
    - E: Young's Modulus (Pa)
    - I: Area Moment of Inertia (m^4)
    """
    L = float(length)
    P = float(load)
    E_mod = float(E)
    I_val = float(I)
    N = int(n_points)
    
    x = np.linspace(0, L, N)
    
    # Cantilever Deflection: y(x) = (P * x^2 * (3*L - x)) / (6 * E * I)
    deflection = (P * (x ** 2) * (3 * L - x)) / (6 * E_mod * I_val)
    
    # Bending Moment: M(x) = P * (L - x)
    bending_moment = P * (L - x)
    
    return x.tolist(), deflection.tolist(), bending_moment.tolist()

def fluid_pipe_pressure_drop(flow_rate=0.01, diameter=0.05, length=100.0, roughness=0.00015, density=1000.0, viscosity=0.001):
    """
    Calculates the pressure drop in a pipe flow using the Darcy-Weisbach equation.
    - flow_rate: Volumetric flow rate (m^3/s)
    - diameter: Inner diameter of the pipe (m)
    - length: Pipe length (m)
    - roughness: Absolute roughness of the pipe material (m)
    - density: Fluid density (kg/m^3)
    - viscosity: Dynamic viscosity (Pa*s)
    """
    Q = float(flow_rate)
    D = float(diameter)
    L = float(length)
    epsilon = float(roughness)
    rho = float(density)
    mu = float(viscosity)
    
    # Area and velocity
    A = np.pi * (D ** 2) / 4.0
    V = Q / A
    
    # Reynolds number
    Re = rho * V * D / mu
    
    if Re < 2300:
        # Laminar flow friction factor
        f = 64.0 / Re
    else:
        # Turbulent flow: Colebrook-White friction factor (Haaland approximation)
        f = 1.0 / (-1.8 * np.log10(((epsilon / D) / 3.7) ** 1.11 + 6.9 / Re)) ** 2
        
    # Darcy-Weisbach equation for pressure drop: delta_P = f * (L/D) * (rho * V^2 / 2)
    delta_P = f * (L / D) * (rho * (V ** 2) / 2.0)
    
    return {
        'pressure_drop_pa': float(delta_P),
        'velocity_m_s': float(V),
        'reynolds_number': float(Re),
        'friction_factor': float(f)
    }

def vibration_1dof(mass=1.0, stiffness=100.0, damping=1.0, force_amplitude=10.0, force_freq=2.0, time_limit=10.0):
    """
    Simulates the transient response of a 1-DOF damped mechanical system under harmonic excitation.
    m*x'' + c*x' + k*x = F0 * cos(w*t)
    """
    m = float(mass)
    k = float(stiffness)
    c = float(damping)
    F0 = float(force_amplitude)
    w_force = float(force_freq)
    t_max = float(time_limit)
    
    dt = 0.01
    t = np.arange(0, t_max, dt)
    
    # Numerical integration using Runge-Kutta 4th order (RK4)
    # State vector: Y = [x, v]
    # Y' = [v, (F0*cos(w*t) - c*v - k*x) / m]
    def deriv(t_val, Y):
        x_val, v_val = Y[0], Y[1]
        a_val = (F0 * np.cos(w_force * t_val) - c * v_val - k * x_val) / m
        return np.array([v_val, a_val])
        
    Y = np.array([0.0, 0.0]) # Initial displacement and velocity are 0
    x_history = []
    v_history = []
    
    for t_step in t:
        x_history.append(Y[0])
        v_history.append(Y[1])
        
        k1 = deriv(t_step, Y)
        k2 = deriv(t_step + 0.5 * dt, Y + 0.5 * dt * k1)
        k3 = deriv(t_step + 0.5 * dt, Y + 0.5 * dt * k2)
        k4 = deriv(t_step + dt, Y + dt * k3)
        
        Y += (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
        
    return t.tolist(), x_history, v_history

def rlc_transient(R=10.0, L=0.1, C=1e-4, V0=12.0, time_limit=0.1):
    """
    Simulates transient response of a series RLC circuit under step voltage input V0.
    L*q'' + R*q' + q/C = V0
    Where q is charge, i = q' is current, V_c = q/C is capacitor voltage.
    """
    R = float(R)
    L_val = float(L)
    C_val = float(C)
    V0 = float(V0)
    t_max = float(time_limit)
    
    dt = t_max / 1000.0
    t = np.arange(0, t_max, dt)
    
    # State: Y = [q, i]
    # Y' = [i, (V0 - R*i - q/C) / L]
    def deriv(t_val, Y):
        q, i = Y[0], Y[1]
        di = (V0 - R * i - q / C_val) / L_val
        return np.array([i, di])
        
    Y = np.array([0.0, 0.0]) # Initial charge and current are 0
    q_history = []
    i_history = []
    
    for t_step in t:
        q_history.append(Y[0])
        i_history.append(Y[1])
        
        k1 = deriv(t_step, Y)
        k2 = deriv(t_step + 0.5 * dt, Y + 0.5 * dt * k1)
        k3 = deriv(t_step + 0.5 * dt, Y + 0.5 * dt * k2)
        k4 = deriv(t_step + dt, Y + dt * k3)
        
        Y += (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
        
    v_c_history = [q / C_val for q in q_history]
    return t.tolist(), v_c_history, i_history

def control_bode_plot(num=None, den=None):
    """
    Computes frequency response (Bode magnitude and phase) of a transfer function H(s) = num(s) / den(s).
    """
    if num is None: num = [1.0]
    if den is None: den = [1.0, 1.0]
    
    num_poly = np.poly1d(num)
    den_poly = np.poly1d(den)
    
    # Generate frequencies logarithmically (0.01 to 1000 rad/s)
    w = np.logspace(-2, 3, 500)
    s = 1j * w
    
    h = num_poly(s) / den_poly(s)
    
    magnitude_db = 20.0 * np.log10(np.abs(h))
    phase_deg = np.rad2deg(np.unwrap(np.angle(h)))
    
    return w.tolist(), magnitude_db.tolist(), phase_deg.tolist()

def aerodynamics_lift_drag(density=1.225, velocity=50.0, area=15.0, Cl=0.5, Cd=0.03):
    """
    Calculates the lift and drag forces acting on an airfoil.
    - density: Fluid density (kg/m^3)
    - velocity: Relative flow velocity (m/s)
    - area: Planform wing area (m^2)
    - Cl: Coefficient of lift
    - Cd: Coefficient of drag
    """
    rho = float(density)
    V = float(velocity)
    S = float(area)
    c_l = float(Cl)
    c_d = float(Cd)
    
    dynamic_pressure = 0.5 * rho * (V ** 2)
    lift = dynamic_pressure * S * c_l
    drag = dynamic_pressure * S * c_d
    
    return {
        'lift_n': float(lift),
        'drag_n': float(drag),
        'dynamic_pressure_pa': float(dynamic_pressure),
        'lift_to_drag_ratio': float(c_l / c_d if c_d != 0 else 0)
    }

def fourier_series_square(t_range=None, terms=5):
    """
    Reconstructs a square wave using a finite Fourier series sum.
    x(t) = (4/pi) * sum_{n=1,3,5,...}^{N} (1/n) * sin(n * w * t)
    """
    if t_range is None:
        t_range = np.linspace(0, 2 * np.pi, 200).tolist()
    t = np.asarray(t_range).astype(float)
    N = int(terms)
    
    w = 1.0 # fundamental frequency
    x = np.zeros_like(t)
    
    for n in range(1, 2 * N, 2):
        x += (1.0 / n) * np.sin(n * w * t)
        
    x *= (4.0 / np.pi)
    return x.tolist()

def projectile_motion(v0=20.0, angle=45.0, h0=0.0, g=9.81):
    """
    Simulates 2D projectile motion.
    Returns: time array, x coordinates, y coordinates, flight time, maximum height, and range.
    """
    v0 = float(v0)
    theta = np.radians(float(angle))
    h0 = float(h0)
    g = float(g)
    
    # Calculate flight time: 0 = h0 + v0*sin(theta)*t - 0.5*g*t^2
    a = -0.5 * g
    b = v0 * np.sin(theta)
    c = h0
    
    discriminant = b**2 - 4*a*c
    t_flight = (-b - np.sqrt(discriminant)) / (2*a)
    
    t = np.linspace(0, t_flight, 200)
    x = v0 * np.cos(theta) * t
    y = h0 + v0 * np.sin(theta) * t - 0.5 * g * (t ** 2)
    
    max_height = h0 + (v0 * np.sin(theta))**2 / (2 * g)
    total_range = v0 * np.cos(theta) * t_flight
    
    return t.tolist(), x.tolist(), y.tolist(), float(t_flight), float(max_height), float(total_range)

def stress_strain_strain_energy(stress=100e6, strain=0.0005):
    """
    Computes the strain energy density (J/m^3) in the elastic region of a material.
    U = 0.5 * stress * strain
    """
    s = float(stress)
    e = float(strain)
    energy = 0.5 * s * e
    return float(energy)

def bernoulli_flow_rate(P1=200000.0, P2=100000.0, z1=0.0, z2=2.0, density=1000.0):
    """
    Calculates flow velocity V2 at downstream section based on pressures, elevations, and Bernoulli's equation.
    Assuming V1 approx 0 (large reservoir transition).
    P1 + rho*g*z1 = P2 + 0.5*rho*V2^2 + rho*g*z2
    """
    p1 = float(P1)
    p2 = float(P2)
    elevation1 = float(z1)
    elevation2 = float(z2)
    rho = float(density)
    g = 9.81
    
    diff_term = (p1 - p2) + rho * g * (elevation1 - elevation2)
    if diff_term < 0:
        return 0.0
        
    V2 = np.sqrt(2.0 * diff_term / rho)
    return float(V2)
