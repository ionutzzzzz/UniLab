import numpy as np

def seir_model(S0=0.99, E0=0.01, I0=0.0, R0=0.0, beta=0.3, sigma=0.2, gamma=0.1, days=100):
    """
    Simulates the SEIR epidemic model.
    S: Susceptible, E: Exposed, I: Infectious, R: Recovered
    beta: transmission rate
    sigma: incubation rate (exposed to infectious)
    gamma: recovery rate
    """
    days = int(days)
    S, E, I, R = [float(S0)], [float(E0)], [float(I0)], [float(R0)]
    
    dt = 0.1  # 0.1 day step
    steps = int(days / dt)
    
    curr_S, curr_E, curr_I, curr_R = S0, E0, I0, R0
    
    for _ in range(steps):
        dS = -beta * curr_S * curr_I
        dE = beta * curr_S * curr_I - sigma * curr_E
        dI = sigma * curr_E - gamma * curr_I
        dR = gamma * curr_I
        
        curr_S += dS * dt
        curr_E += dE * dt
        curr_I += dI * dt
        curr_R += dR * dt
        
        S.append(curr_S)
        E.append(curr_E)
        I.append(curr_I)
        R.append(curr_R)
        
    t = np.linspace(0, days, len(S)).tolist()
    return t, S, E, I, R

def hodgkin_huxley(I_ext=10.0, duration=50.0):
    """
    Simulates Hodgkin-Huxley model of a neuron's action potential.
    I_ext: external current injection (uA/cm^2)
    duration: total simulation time (ms)
    """
    I_ext = float(I_ext)
    duration = float(duration)
    
    # Constants
    C_m = 1.0     # membrane capacitance (uF/cm^2)
    g_Na = 120.0  # max sodium conductance (mS/cm^2)
    g_K = 36.0    # max potassium conductance (mS/cm^2)
    g_L = 0.3     # max leak conductance (mS/cm^2)
    E_Na = 50.0   # sodium reversal potential (mV)
    E_K = -77.0   # potassium reversal potential (mV)
    E_L = -54.387 # leak reversal potential (mV)
    
    # Time steps
    dt = 0.01     # ms
    steps = int(duration / dt)
    
    # Gating variables functions
    def alpha_m(V): return 0.1 * (V + 40.0) / (1.0 - np.exp(-(V + 40.0) / 10.0)) if V != -40.0 else 1.0
    def beta_m(V):  return 4.0 * np.exp(-(V + 65.0) / 18.0)
    
    def alpha_h(V): return 0.07 * np.exp(-(V + 65.0) / 20.0)
    def beta_h(V):  return 1.0 / (1.0 + np.exp(-(V + 35.0) / 10.0))
    
    def alpha_n(V): return 0.01 * (V + 55.0) / (1.0 - np.exp(-(V + 55.0) / 10.0)) if V != -55.0 else 0.1
    def beta_n(V):  return 0.125 * np.exp(-(V + 65.0) / 80.0)
    
    # Initial states
    V = -65.0     # membrane potential
    m = alpha_m(V) / (alpha_m(V) + beta_m(V))
    h = alpha_h(V) / (alpha_h(V) + beta_h(V))
    n = alpha_n(V) / (alpha_n(V) + beta_n(V))
    
    V_arr, m_arr, h_arr, n_arr = [V], [m], [h], [n]
    
    for _ in range(steps):
        # External current stimulus
        I_stim = I_ext if 10.0 <= len(V_arr)*dt <= 40.0 else 0.0
        
        # Currents
        I_Na = g_Na * (m**3) * h * (V - E_Na)
        I_K = g_K * (n**4) * (V - E_K)
        I_L = g_L * (V - E_L)
        
        # Derivatives
        dV = (I_stim - (I_Na + I_K + I_L)) / C_m
        dm = alpha_m(V) * (1.0 - m) - beta_m(V) * m
        dh = alpha_h(V) * (1.0 - h) - beta_h(V) * h
        dn = alpha_n(V) * (1.0 - n) - beta_n(V) * n
        
        V += dV * dt
        m += dm * dt
        h += dh * dt
        n += dn * dt
        
        V_arr.append(V)
        m_arr.append(m)
        h_arr.append(h)
        n_arr.append(n)
        
    t = np.linspace(0, duration, len(V_arr)).tolist()
    return t, V_arr, m_arr, h_arr, n_arr

def dna_align(seq1, seq2, match=2, mismatch=-1, gap=-2):
    """
    Performs Needleman-Wunsch global alignment of two DNA sequences.
    """
    match = int(match)
    mismatch = int(mismatch)
    gap = int(gap)
    
    n, m = len(seq1), len(seq2)
    score_matrix = np.zeros((n + 1, m + 1))
    
    for i in range(n + 1):
        score_matrix[i][0] = i * gap
    for j in range(m + 1):
        score_matrix[0][j] = j * gap
        
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            s = match if seq1[i - 1] == seq2[j - 1] else mismatch
            score_matrix[i][j] = max(
                score_matrix[i - 1][j - 1] + s,
                score_matrix[i - 1][j] + gap,
                score_matrix[i][j - 1] + gap
            )
            
    # Traceback to reconstruct alignment
    align1, align2 = "", ""
    i, j = n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0:
            s = match if seq1[i - 1] == seq2[j - 1] else mismatch
            if score_matrix[i][j] == score_matrix[i - 1][j - 1] + s:
                align1 = seq1[i - 1] + align1
                align2 = seq2[j - 1] + align2
                i -= 1
                j -= 1
                continue
        if i > 0 and (j == 0 or score_matrix[i][j] == score_matrix[i - 1][j] + gap):
            align1 = seq1[i - 1] + align1
            align2 = "-" + align2
            i -= 1
        else:
            align1 = "-" + align1
            align2 = seq2[j - 1] + align2
            j -= 1
            
    return {
        'score': float(score_matrix[n][m]),
        'aligned_seq1': align1,
        'aligned_seq2': align2
    }

def cardiac_action_potential(duration=100.0):
    """
    Simulates the FitzHugh-Nagumo model of cardiac action potential excitation and recovery.
    dv/dt = v - v^3/3 - w + I
    dw/dt = (v + a - b*w) * tau
    """
    duration = float(duration)
    
    # Parameters
    a = 0.7
    b = 0.8
    tau = 0.08
    I_external = 0.5 # stimulus current
    
    dt = 0.05
    steps = int(duration / dt)
    
    # Initial conditions
    v = -1.0 # membrane potential excitation
    w = -0.5 # recovery variable
    
    v_arr, w_arr = [v], [w]
    
    for step in range(steps):
        # Pulse stimulus
        I = I_external if 10.0 <= step * dt <= 20.0 else 0.0
        
        dv = v - (v ** 3) / 3.0 - w + I
        dw = (v + a - b * w) * tau
        
        v += dv * dt
        w += dw * dt
        
        v_arr.append(v)
        w_arr.append(w)
        
    t = np.linspace(0, duration, len(v_arr)).tolist()
    return t, v_arr, w_arr

def enzyme_kinetics(substrate_concs=None, Vmax=100.0, Km=5.0):
    """
    Calculates chemical reaction rates using the Michaelis-Menten model.
    v = (Vmax * [S]) / (Km + [S])
    """
    if substrate_concs is None:
        substrate_concs = [0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0]
        
    V = float(Vmax)
    K = float(Km)
    S = np.asarray(substrate_concs).astype(float)
    
    rates = (V * S) / (K + S)
    
    return S.tolist(), rates.tolist()

def lotka_volterra(alpha=1.1, beta=0.4, delta=0.1, gamma=0.4, x0=10.0, y0=5.0, time_limit=50.0):
    """
    Simulates the Lotka-Volterra predator-prey system.
    dx/dt = alpha*x - beta*x*y   (Prey population)
    dy/dt = delta*x*y - gamma*y   (Predator population)
    """
    alpha = float(alpha)
    beta = float(beta)
    delta = float(delta)
    gamma = float(gamma)
    x0 = float(x0)
    y0 = float(y0)
    t_max = float(time_limit)
    
    dt = 0.05
    steps = int(t_max / dt)
    t = np.arange(0, t_max, dt)
    
    x, y = x0, y0
    x_history = [x]
    y_history = [y]
    
    for _ in range(1, len(t)):
        dx = alpha * x - beta * x * y
        dy = delta * x * y - gamma * y
        
        x += dx * dt
        y += dy * dt
        
        # Populations cannot drop below zero
        x = max(0.0, x)
        y = max(0.0, y)
        
        x_history.append(x)
        y_history.append(y)
        
    return t.tolist(), x_history, y_history

def pharmacokinetics_2comp(dose=100.0, k12=0.05, k21=0.02, kel=0.03, V1=10.0, V2=20.0, duration=72.0):
    """
    Simulates a two-compartment pharmacokinetics (PK) drug distribution model after IV bolus injection.
    C1: central compartment drug concentration
    C2: peripheral compartment drug concentration
    """
    dose = float(dose)
    k12 = float(k12)
    k21 = float(k21)
    kel = float(kel)
    V1 = float(V1)
    V2 = float(V2)
    t_max = float(duration)
    
    dt = 0.1
    t = np.arange(0, t_max, dt)
    
    # State: A = [A1, A2] (drug amount in compartment 1 and 2)
    # dA1/dt = -kel*A1 - k12*A1 + k21*A2
    # dA2/dt = k12*A1 - k21*A2
    def deriv(t_val, A):
        a1, a2 = A[0], A[1]
        da1 = -kel * a1 - k12 * a1 + k21 * a2
        da2 = k12 * a1 - k21 * a2
        return np.array([da1, da2])
        
    A = np.array([dose, 0.0]) # Initial bolus dose in central compartment
    c1_history = []
    c2_history = []
    
    for t_step in t:
        c1_history.append(A[0] / V1)
        c2_history.append(A[1] / V2)
        
        k1 = deriv(t_step, A)
        k2 = deriv(t_step + 0.5 * dt, A + 0.5 * dt * k1)
        k3 = deriv(t_step + 0.5 * dt, A + 0.5 * dt * k2)
        k4 = deriv(t_step + dt, A + dt * k3)
        
        A += (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
        
    return t.tolist(), c1_history, c2_history

def cardiac_output(stroke_volume=70.0, heart_rate=72.0):
    """
    Computes cardiac output (L/min) based on Stroke Volume (mL) and Heart Rate (bpm).
    CO = (SV * HR) / 1000
    """
    sv = float(stroke_volume)
    hr = float(heart_rate)
    co = (sv * hr) / 1000.0
    return {
        'cardiac_output_l_min': float(co),
        'stroke_volume_ml': sv,
        'heart_rate_bpm': hr
    }

def dna_transcription(dna_sequence="ATGCGATACGTT"):
    """
    Transcribes a DNA sequence to RNA and translates it to protein codon sequence.
    """
    dna = str(dna_sequence).upper()
    rna = dna.replace('T', 'U')
    
    # Genetic code codon table
    codon_table = {
        'AUA':'I', 'AUC':'I', 'AUU':'I', 'AUG':'M',
        'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACU':'T',
        'AAC':'N', 'AAU':'N', 'AAG':'K', 'AAA':'K',
        'AGC':'S', 'AGU':'S', 'AGA':'R', 'AGG':'R',
        'CUA':'L', 'CUC':'L', 'CUG':'L', 'CUU':'L',
        'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCU':'P',
        'CAC':'H', 'CAU':'H', 'CAG':'Q', 'CAA':'Q',
        'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGU':'R',
        'GUA':'V', 'GUC':'V', 'GUG':'V', 'GUU':'V',
        'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCU':'A',
        'GAC':'D', 'GAU':'D', 'GAG':'E', 'GAA':'E',
        'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGU':'G',
        'UCA':'S', 'UCC':'S', 'UCG':'S', 'UCU':'S',
        'UUC':'F', 'UUU':'F', 'UUA':'L', 'UUG':'L',
        'UAC':'Y', 'UAU':'Y', 'UAA':'_Stop_', 'UAG':'_Stop_', 'UGA':'_Stop_',
        'UGC':'C', 'UGU':'C', 'UGG':'W',
    }
    
    protein = ""
    for i in range(0, len(rna) - 2, 3):
        codon = rna[i:i+3]
        amino_acid = codon_table.get(codon, '?')
        if amino_acid == '_Stop_':
            protein += "*"
            break
        protein += amino_acid
        
    return {
        'rna_sequence': rna,
        'protein_sequence': protein
    }

def cardiac_stroke_volume(EDV=120.0, ESV=50.0):
    """
    Computes stroke volume (mL) and ejection fraction (%) from End-Diastolic Volume (EDV) and End-Systolic Volume (ESV).
    SV = EDV - ESV
    EF = (SV / EDV) * 100
    """
    edv = float(EDV)
    esv = float(ESV)
    sv = edv - esv
    ef = (sv / edv) * 100.0 if edv != 0 else 0.0
    return {
        'stroke_volume_ml': float(sv),
        'ejection_fraction_pct': float(ef)
    }

def pharmacokinetics_1comp(dose=100.0, ka=0.8, kel=0.1, Vd=15.0, duration=24.0):
    """
    Simulates a one-compartment PK model for oral drug administration.
    C(t) = (F * Dose * ka) / (Vd * (ka - kel)) * (exp(-kel*t) - exp(-ka*t))
    F is assumed to be 1.0 (bioavailability).
    """
    dose = float(dose)
    ka = float(ka)
    kel = float(kel)
    Vd = float(Vd)
    t_max = float(duration)
    
    t = np.linspace(0, t_max, 200)
    
    if abs(ka - kel) < 1e-5:
        ka += 1e-5 # Guard against division by zero
        
    term = (dose * ka) / (Vd * (ka - kel))
    c = term * (np.exp(-kel * t) - np.exp(-ka * t))
    
    return t.tolist(), c.tolist()

def dna_gc_content(dna_sequence="ATGCGATACGTT"):
    """
    Calculates the GC content ratio (%) of a DNA sequence.
    """
    dna = str(dna_sequence).upper()
    g_count = dna.count('G')
    c_count = dna.count('C')
    total = len(dna)
    
    ratio = (g_count + c_count) / total * 100.0 if total > 0 else 0.0
    return float(ratio)
