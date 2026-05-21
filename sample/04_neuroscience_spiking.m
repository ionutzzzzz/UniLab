% 04_neuroscience_spiking.m
% UniLab Neuroscience: Neuron Dynamics & Hodgkin-Huxley Model

clear all;
clc;

disp('🧠 UniLab Computational Neuroscience');
disp('=====================================');

%% 1. Leaky Integrate-and-Fire (LIF) Neuron
disp('--- 1. Leaky Integrate-and-Fire Model ---');
dt_v = 0.1; t_e = 100.0;
V_m = -70.0; V_t = -50.0; V_r = -75.0;
tau_v = 20.0; R_v = 1.0; I_e = 25.0;

t_v = 0:dt_v:t_e;
V_h = zeros(1, size(t_v, 2));

for i = 1:size(t_v, 2)
    dV = (-(V_m - V_r) + R_v * I_e) / tau_v * dt_v;
    V_m = V_m + dV;
    if V_m >= V_t
        V_m = V_r;
    end
    V_h(i) = V_m;
end

figure;
plot(t_v, V_h, 'LineWidth', 1.5);
title('LIF Neuron Membrane Potential');
xlabel('Time (ms)'); ylabel('Potential (mV)');
grid on;

%% 2. Hodgkin-Huxley Spiking Dynamics
disp(' ');
disp('--- 2. Hodgkin-Huxley Spiking Simulator ---');

function s_n = hh_step(s_c, p_p)
    s_n = s_c;
    dt_s = 0.01; I_v = 10.0;
    V_val = s_c.V; m_val = s_c.m; h_val = s_c.h; n_val = s_c.n;
    
    am = 0.1*(V_val+40.0)/(1.0-exp(-(V_val+40.0)/10.0));
    bm = 4.0*exp(-(V_val+65.0)/18.0);
    ah = 0.07*exp(-(V_val+65.0)/20.0);
    bh = 1.0/(1.0+exp(-(V_val+35.0)/10.0));
    an = 0.01*(V_val+55.0)/(1.0-exp(-(V_val+55.0)/10.0));
    bn = 0.125*exp(-(V_val+65.0)/80.0);
    
    dm = (am*(1.0-m_val) - bm*m_val);
    dh = (ah*(1.0-h_val) - bh*h_val);
    dn = (an*(1.0-n_val) - bn*n_val);
    
    gNa = 120.0; gK = 36.0; gL = 0.3;
    ENa = 50.0; EK = -77.0; EL = -54.387;
    
    dV = (I_v - gNa*m_val^3*h_val*(V_val-ENa) - gK*n_val^4*(V_val-EK) - gL*(V_val-EL));
    
    s_n.V = V_val + dV * dt_s;
    s_n.m = m_val + dm * dt_s;
    s_n.h = h_val + dh * dt_s;
    s_n.n = n_val + dn * dt_s;
    s_n.h_v = [s_c.h_v; s_n.V];
    if size(s_n.h_v, 1) > 500, s_n.h_v = s_n.h_v(end-499:end); end
end

function hh_draw(ax_o, s_d)
    plot(ax_o, s_d.h_v, 'r-', 'LineWidth', 2);
    title(ax_o, 'Hodgkin-Huxley Action Potential');
    ylabel(ax_o, 'Voltage (mV)');
end

st_hh = struct('V', -65.0, 'm', 0.05, 'h', 0.6, 'n', 0.32, 'h_v', []);
simulate('algorithm', 'step', @hh_step, 'draw', @hh_draw, 'state', st_hh);

disp('Neuroscience Session Complete.');
