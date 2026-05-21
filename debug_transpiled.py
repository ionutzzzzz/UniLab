




unilab_clear_workspace(globals())


unilab_call(clc)



unilab_call(disp, '🤖 UniLab Robotics Laboratory')


unilab_call(disp, '==============================')





unilab_call(disp, '--- 1. Forward Kinematics ---')


L1 = 1.0
L2 = 0.8



def arm_fk(theta1=None, theta2=None, L1=None, L2=None):
    nargin = unilab_nargin_sum(1 for x in [theta1, theta2, L1, L2] if x is not None)

    

    
    x = (unilab_mul(unilab_call(L1), unilab_call(cos, unilab_call(theta1))) + unilab_mul(unilab_call(L2), unilab_call(cos, (unilab_call(theta1) + unilab_call(theta2)))))

    
    y = (unilab_mul(unilab_call(L1), unilab_call(sin, unilab_call(theta1))) + unilab_mul(unilab_call(L2), unilab_call(sin, (unilab_call(theta1) + unilab_call(theta2)))))

    
    pos = unilab_matrix_concat([unilab_call(x), unilab_call(y)])


    return pos


t1 = unilab_div(pi, 4)
t2 = unilab_div(pi, 6)


p = unilab_call(arm_fk, unilab_call(t1), unilab_call(t2), unilab_call(L1), unilab_call(L2))


unilab_call(fprintf, 'Arm Tip Position for [%.2f, %.2f]: (%.2f, %.2f)\\n', unilab_call(t1), unilab_call(t2), unilab_call(p, 1), unilab_call(p, 2))





unilab_call(disp, '--- 2. Inverse Kinematics ---')



def arm_ik(x=None, y=None, L1=None, L2=None):
    nargin = unilab_nargin_sum(1 for x in [x, y, L1, L2] if x is not None)

    

    
    D = unilab_div((unilab_pow(unilab_call(x), 2) + unilab_pow(unilab_call(y), 2) - unilab_pow(unilab_call(L1), 2) - unilab_pow(unilab_call(L2), 2)), unilab_mul(unilab_mul(2, unilab_call(L1)), unilab_call(L2)))

    

    
    t2 = unilab_call(atan2, unilab_call(sqrt, (1 - unilab_pow(unilab_call(D), 2))), unilab_call(D))

    
    t1 = (unilab_call(atan2, unilab_call(y), unilab_call(x)) - unilab_call(atan2, unilab_mul(unilab_call(L2), unilab_call(sin, unilab_call(t2))), (unilab_call(L1) + unilab_mul(unilab_call(L2), unilab_call(cos, unilab_call(t2))))))

    
    q = unilab_matrix_concat([unilab_call(t1), unilab_call(t2)])


    return q


q_res = unilab_call(arm_ik, unilab_call(p, 1), unilab_call(p, 2), unilab_call(L1), unilab_call(L2))


unilab_call(disp, 'IK Result (Should match test FK angles):')


unilab_call(disp, unilab_call(q_res))





unilab_call(disp, '--- 3. Path Following Simulation ---')


N_pts = 100


t_path = unilab_call(linspace, 0, unilab_mul(2, pi), unilab_call(N_pts))


center = unilab_matrix_concat([0.8, 0.8])
radius = 0.4



x_path = (unilab_call(center, 1) + unilab_mul(unilab_call(radius), unilab_call(cos, unilab_call(t_path))))


y_path = (unilab_call(center, 2) + unilab_mul(unilab_call(radius), unilab_call(sin, unilab_call(t_path))))



theta_hist = unilab_call(zeros, unilab_call(N_pts), 2)


for i in unilab_iter(unilab_range(1, unilab_call(N_pts))):
    unilab_set(theta_hist, unilab_call(arm_ik, unilab_call(x_path, i), unilab_call(y_path, i), unilab_call(L1), unilab_call(L2)), i, slice(None))


unilab_call(figure)


unilab_call(plot, unilab_call(x_path), unilab_call(y_path), 'k--', 'LineWidth', 1)
hold('on')




q_ex = unilab_call(theta_hist, 50, slice(None))


j1 = unilab_matrix_concat([unilab_mul(unilab_call(L1), unilab_call(cos, unilab_call(q_ex, 1))), unilab_mul(unilab_call(L1), unilab_call(sin, unilab_call(q_ex, 1)))])


unilab_call(plot, unilab_matrix_concat([0, unilab_call(j1, 1), unilab_call(x_path, 50)]), unilab_matrix_concat([0, unilab_call(j1, 2), unilab_call(y_path, 50)]), 'bo-', 'LineWidth', 3)


unilab_call(title, 'Robotic Arm Circular Trajectory Planning')


unilab_call(xlabel, 'X (m)')
unilab_call(ylabel, 'Y (m)')


axis('equal')
grid('on')





unilab_call(disp, ' ')


unilab_call(disp, '--- 4. Interactive Robot Arm Animation ---')



def robot_step(s_c=None, p_p=None):
    nargin = unilab_nargin_sum(1 for x in [s_c, p_p] if x is not None)

    
    s_n = unilab_call(s_c)

    
    unilab_set(s_n, (unilab_get(s_c, 't') + 0.05), 't')

    

    
    xt = (0.8 + unilab_mul(0.3, unilab_call(sin, unilab_get(s_n, 't'))))

    
    yt = (0.8 + unilab_mul(0.3, unilab_call(cos, unilab_mul(unilab_get(s_n, 't'), 0.5))))

    
    q = unilab_call(arm_ik, unilab_call(xt), unilab_call(yt), 1.0, 0.8)

    
    unilab_set(s_n, unilab_call(q), 'q')

    
    unilab_set(s_n, unilab_matrix_concat([unilab_call(xt), unilab_call(yt)]), 'target')

    
    unilab_set(s_n, unilab_matrix_concat([unilab_get(s_c, 'h')], [unilab_matrix_concat([unilab_call(xt), unilab_call(yt)])]), 'h')

    
    if unilab_to_bool(unilab_gt(unilab_call(size, unilab_get(s_n, 'h'), 1), 200)):
        unilab_set(s_n, unilab_call(unilab_get(s_n, 'h'), unilab_range((unilab_end - 199), unilab_end), slice(None)), 'h')
    return s_n
def robot_draw(ax=None, s=None):
    nargin = unilab_nargin_sum(1 for x in [ax, s] if x is not None)

    
    L1 = 1.0
    L2 = 0.8

    
    j1 = unilab_matrix_concat([unilab_mul(unilab_call(L1), unilab_call(cos, unilab_call(unilab_get(s, 'q'), 1))), unilab_mul(unilab_call(L1), unilab_call(sin, unilab_call(unilab_get(s, 'q'), 1)))])

    
    tip = unilab_matrix_concat([(unilab_call(j1, 1) + unilab_mul(unilab_call(L2), unilab_call(cos, (unilab_call(unilab_get(s, 'q'), 1) + unilab_call(unilab_get(s, 'q'), 2))))), (unilab_call(j1, 2) + unilab_mul(unilab_call(L2), unilab_call(sin, (unilab_call(unilab_get(s, 'q'), 1) + unilab_call(unilab_get(s, 'q'), 2)))))])

    
    
    unilab_call(plot, unilab_call(ax), unilab_call(unilab_get(s, 'h'), slice(None), 1), unilab_call(unilab_get(s, 'h'), slice(None), 2), 'g:', 'LineWidth', 1)
    unilab_call(hold, unilab_call(ax), 'on')

    
    unilab_call(plot, unilab_call(ax), unilab_matrix_concat([0, unilab_call(j1, 1), unilab_call(tip, 1)]), unilab_matrix_concat([0, unilab_call(j1, 2), unilab_call(tip, 2)]), 'b-o', 'LineWidth', 4, 'MarkerSize', 10)

    
    unilab_call(plot, unilab_call(ax), unilab_call(unilab_get(s, 'target'), 1), unilab_call(unilab_get(s, 'target'), 2), 'rx', 'MarkerSize', 15, 'LineWidth', 2)

    
    unilab_call(title, unilab_call(ax), 'Real-time Inverse Kinematics Tracking')

    
    unilab_call(xlim, unilab_call(ax), unilab_matrix_concat([-0.5, 2.0]))
    unilab_call(ylim, unilab_call(ax), unilab_matrix_concat([-0.5, 2.0]))
    unilab_call(grid, unilab_call(ax), 'on')
    unilab_call(hold, unilab_call(ax), 'off')


st_r = unilab_call(struct, 't', 0, 'q', unilab_matrix_concat([0, 0]), 'target', unilab_matrix_concat([1.2, 0.5]), 'h', unilab_matrix_concat())


unilab_call(simulate, 'algorithm', 'step', unilab_handle(robot_step), 'draw', unilab_handle(robot_draw), 'state', unilab_call(st_r))



unilab_call(disp, 'Robotics Kinematics Session Complete.')

