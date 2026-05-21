import matplotlib.pyplot as plt
plt.subplot(1, 2, 1)
plt.plot([1, 2], [3, 4])
plt.clf() # Clears figure
plt.plot([1, 2], [4, 3])
plt.show() # Only one plot will be shown, taking full figure
