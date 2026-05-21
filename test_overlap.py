import matplotlib.pyplot as plt
plt.subplot(1, 2, 1)
# Simulate UniLab plot: plt.clf() then plt.plot()
plt.clf()
plt.plot([0, 1], [0, 1]) # This creates axes (1,1,1)
# Next subplot
plt.subplot(1, 2, 2)
plt.plot([0, 1], [1, 0])
# Now check how many axes we have
print(f"Number of axes: {len(plt.gcf().axes)}")
for i, ax in enumerate(plt.gcf().axes):
    print(f"Axes {i} geometry: {ax.get_subplotspec().get_geometry() if hasattr(ax, 'get_subplotspec') else 'Not a subplot'}")
