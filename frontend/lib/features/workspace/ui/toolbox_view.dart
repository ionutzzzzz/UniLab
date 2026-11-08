import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/ui_theme.dart';
import '../../../widgets/ui_button.dart';
import '../../../widgets/ui_text.dart';

enum EngineeringToolCategory {
  control('Control', LucideIcons.slidersHorizontal, 'Control Systems & PID Studio'),
  signal('Signal', LucideIcons.activity, 'Signal Processing & Filter Designer'),
  matrix('Matrix', LucideIcons.grid3x3, 'Matrix & Linear Algebra Lab'),
  ode('ODE / Num', LucideIcons.sigma, 'ODE Solver & Numerical Methods'),
  units('Units / Const', LucideIcons.compass, 'Unit Converter & SI Constants'),
  templates('Templates', LucideIcons.fileCode2, 'Engineering Script Templates');

  const EngineeringToolCategory(this.shortLabel, this.icon, this.fullTitle);
  final String shortLabel;
  final IconData icon;
  final String fullTitle;
}

class EngineeringToolboxDialog {
  static Future<void> show(
    BuildContext context, {
    EngineeringToolCategory initialCategory = EngineeringToolCategory.control,
  }) async {
    final ui = UiTheme.of(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: ui.colors.panel,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ui.colors.border),
        ),
        child: SizedBox(
          width: 980,
          height: 680,
          child: Column(
            children: [
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ui.colors.panelHeader,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(
                    bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.6)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.wrench, size: 18, color: ui.colors.accent),
                    const SizedBox(width: 10),
                    const UiText(
                      text: 'UniLab Engineering Workbench & Toolbox',
                      variant: UiTextVariant.body,
                      fontWeight: FontWeight.bold,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 16, color: ui.colors.textMuted),
                      tooltip: 'Close Workbench',
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ToolboxView(
                  initialCategory: initialCategory,
                  isDialogMode: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolboxView extends StatefulWidget {
  const ToolboxView({
    super.key,
    this.initialCategory = EngineeringToolCategory.control,
    this.isDialogMode = false,
  });

  final EngineeringToolCategory initialCategory;
  final bool isDialogMode;

  @override
  State<ToolboxView> createState() => _ToolboxViewState();
}

class _ToolboxViewState extends State<ToolboxView> {
  late EngineeringToolCategory _category;

  // 1. Control Systems Controllers
  final TextEditingController _tfVarCtrl = TextEditingController(text: 'G');
  final TextEditingController _tfNumCtrl = TextEditingController(text: '[10]');
  final TextEditingController _tfDenCtrl = TextEditingController(text: '[1, 2, 10]');
  String _loopMode = 'PID Closed-Loop';
  double _kp = 2.0;
  double _ki = 1.5;
  double _kd = 0.3;

  // 2. Signal Processing & Filter Designer Controllers
  String _filterFamily = 'butter';
  String _filterType = 'low';
  int _filterOrder = 4;
  final TextEditingController _fsCtrl = TextEditingController(text: '1000');
  final TextEditingController _fc1Ctrl = TextEditingController(text: '120');
  final TextEditingController _fc2Ctrl = TextEditingController(text: '250');
  final TextEditingController _rippleCtrl = TextEditingController(text: '1.0');
  String _testWaveform = 'Multi-Tone + Noise';

  // 3. Matrix & Linear Algebra Controllers
  final TextEditingController _matACtrl =
      TextEditingController(text: '[4, -1, 0; -1, 4, -1; 0, -1, 4]');
  final TextEditingController _vecBCtrl = TextEditingController(text: '[15; 10; 15]');

  // 4. ODE & Numerical Methods Controllers
  String _odePreset = 'Mass-Spring-Damper';
  final TextEditingController _odeTmaxCtrl = TextEditingController(text: '20');
  final TextEditingController _odeParam1Ctrl = TextEditingController(text: '1.0');
  final TextEditingController _odeParam2Ctrl = TextEditingController(text: '0.4');
  final TextEditingController _odeParam3Ctrl = TextEditingController(text: '4.0');
  final TextEditingController _polyCtrl = TextEditingController(text: '[1, -6, 11, -6]');

  // 5. Unit Converter State
  String _unitCategory = 'Frequency';
  final TextEditingController _unitInputCtrl = TextEditingController(text: '50');
  final TextEditingController _lcLValCtrl = TextEditingController(text: '1e-3');
  final TextEditingController _lcCValCtrl = TextEditingController(text: '1e-6');

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _tfVarCtrl.dispose();
    _tfNumCtrl.dispose();
    _tfDenCtrl.dispose();
    _fsCtrl.dispose();
    _fc1Ctrl.dispose();
    _fc2Ctrl.dispose();
    _rippleCtrl.dispose();
    _matACtrl.dispose();
    _vecBCtrl.dispose();
    _odeTmaxCtrl.dispose();
    _odeParam1Ctrl.dispose();
    _odeParam2Ctrl.dispose();
    _odeParam3Ctrl.dispose();
    _polyCtrl.dispose();
    _unitInputCtrl.dispose();
    _lcLValCtrl.dispose();
    _lcCValCtrl.dispose();
    super.dispose();
  }

  void _runCode(String code) {
    final appProvider = context.read<AppProvider>();
    appProvider.runConsoleCommand(code);
    if (widget.isDialogMode && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _insertCode(String code, {String? suggestedName, bool replaceAll = false}) {
    final appProvider = context.read<AppProvider>();
    appProvider.insertCodeIntoActiveScript(
      code,
      replaceAll: replaceAll,
      suggestedFileName: suggestedName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code inserted into active editor script.'),
          duration: Duration(milliseconds: 1400),
        ),
      );
      if (widget.isDialogMode) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Selector Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: ui.colors.panelHeader,
            border: Border(
              bottom: BorderSide(color: ui.colors.divider.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EngineeringToolCategory.values.map((cat) {
                      final isSelected = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => setState(() => _category = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ui.colors.accent.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? ui.colors.accent
                                    : ui.colors.divider.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 13,
                                  color: isSelected ? ui.colors.accent : ui.colors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                UiText(
                                  text: cat.shortLabel,
                                  variant: UiTextVariant.caption,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? ui.colors.accent : ui.colors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (!widget.isDialogMode)
                IconButton(
                  icon: Icon(LucideIcons.maximize2, size: 14, color: ui.colors.accent),
                  tooltip: 'Open Full Engineering Workbench',
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                  onPressed: () => EngineeringToolboxDialog.show(
                    context,
                    initialCategory: _category,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildCategoryBody(ui),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBody(UiTheme ui) {
    switch (_category) {
      case EngineeringToolCategory.control:
        return _buildControlStudio(ui);
      case EngineeringToolCategory.signal:
        return _buildSignalStudio(ui);
      case EngineeringToolCategory.matrix:
        return _buildMatrixStudio(ui);
      case EngineeringToolCategory.ode:
        return _buildOdeStudio(ui);
      case EngineeringToolCategory.units:
        return _buildUnitsStudio(ui);
      case EngineeringToolCategory.templates:
        return _buildTemplatesStudio(ui);
    }
  }

  // ===========================================================================
  // 1. CONTROL SYSTEMS & PID STUDIO
  // ===========================================================================
  String _buildControlSystemPreamble() {
    final v = _tfVarCtrl.text.trim().isEmpty ? 'G' : _tfVarCtrl.text.trim();
    final numStr = _tfNumCtrl.text.trim().isEmpty ? '[10]' : _tfNumCtrl.text.trim();
    final denStr = _tfDenCtrl.text.trim().isEmpty ? '[1, 2, 10]' : _tfDenCtrl.text.trim();
    final kpStr = _kp.toStringAsFixed(2);
    final kiStr = _ki.toStringAsFixed(2);
    final kdStr = _kd.toStringAsFixed(2);

    if (_loopMode == 'Open-Loop G(s)') {
      return '$v = tf($numStr, $denStr);\nsys_active = $v;';
    } else if (_loopMode == 'Unity Feedback') {
      return '$v = tf($numStr, $denStr);\nsys_active = feedback($v, 1);';
    } else {
      return '$v = tf($numStr, $denStr);\n'
          'C_pid = pid($kpStr, $kiStr, $kdStr);\n'
          'sys_active = feedback(series(C_pid, $v), 1);';
    }
  }

  Widget _buildControlStudio(UiTheme ui) {
    final v = _tfVarCtrl.text.trim().isEmpty ? 'G' : _tfVarCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          ui,
          title: 'Transfer Function & Loop Architecture',
          icon: LucideIcons.slidersHorizontal,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: _labeledField(ui, 'System Var', _tfVarCtrl),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _labeledField(ui, 'Numerator num(s)', _tfNumCtrl),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _labeledField(ui, 'Denominator den(s)', _tfDenCtrl),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _presetChip(ui, '2nd-Order Underdamped', () {
                  setState(() {
                    _tfNumCtrl.text = '[25]';
                    _tfDenCtrl.text = '[1, 2, 25]';
                  });
                }),
                _presetChip(ui, '3rd-Order Servo Plant', () {
                  setState(() {
                    _tfNumCtrl.text = '[10]';
                    _tfDenCtrl.text = 'conv([1, 0], [1, 4, 8])';
                  });
                }),
                _presetChip(ui, 'Non-Minimum Phase', () {
                  setState(() {
                    _tfNumCtrl.text = '[-1, 3]';
                    _tfDenCtrl.text = '[1, 3, 2]';
                  });
                }),
              ],
            ),
            const SizedBox(height: 10),
            _dropdownRow(
              ui,
              label: 'Configuration',
              value: _loopMode,
              items: const ['PID Closed-Loop', 'Unity Feedback', 'Open-Loop G(s)'],
              onChanged: (val) => setState(() => _loopMode = val!),
            ),
            if (_loopMode == 'PID Closed-Loop') ...[
              const SizedBox(height: 8),
              _sliderRow(ui, 'Kp (Proportional)', _kp, 0.0, 20.0, (val) => setState(() => _kp = val)),
              _sliderRow(ui, 'Ki (Integral)', _ki, 0.0, 15.0, (val) => setState(() => _ki = val)),
              _sliderRow(ui, 'Kd (Derivative)', _kd, 0.0, 5.0, (val) => setState(() => _kd = val)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _sectionCard(
          ui,
          title: 'One-Click Analysis & Plots (Local Plot Tab)',
          icon: LucideIcons.lineChart,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChipButton(ui, 'Step Response', LucideIcons.trendingUp, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nstep(sys_active);\ntitle("Step Response ($_loopMode)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Impulse', LucideIcons.zap, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nimpulse(sys_active);\ntitle("Impulse Response ($_loopMode)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Bode Plot', LucideIcons.activity, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nbode($v);\ntitle("Bode Diagram of $v(s)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Stability Margins', LucideIcons.shieldCheck, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nmargin($v);\ndamp(sys_active);');
                }),
                _actionChipButton(ui, 'Root Locus', LucideIcons.gitBranch, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nrlocus($v);\ntitle("Root Locus of $v(s)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Nyquist', LucideIcons.refreshCw, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nnyquist($v);\ntitle("Nyquist Diagram of $v(s)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Nichols', LucideIcons.compass, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\nnichols($v);\ntitle("Nichols Chart of $v(s)");\ngrid on;');
                }),
                _actionChipButton(ui, 'Pole-Zero Map', LucideIcons.crosshair, () {
                  final pre = _buildControlSystemPreamble();
                  _runCode('$pre\nfigure;\npzmap(sys_active);\ntitle("Pole-Zero Map ($_loopMode)");\ngrid on;');
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: UiButton(
                    label: 'Full 4-Plot Control Suite',
                    icon: LucideIcons.layoutGrid,
                    variant: UiButtonVariant.primary,
                    onPressed: () {
                      final pre = _buildControlSystemPreamble();
                      _runCode(
                        '$pre\n'
                        'figure;\n'
                        'subplot(2, 2, 1); step(sys_active); title("Step Response"); grid on;\n'
                        'subplot(2, 2, 2); pzmap(sys_active); title("Pole-Zero Map"); grid on;\n'
                        'subplot(2, 2, 3); rlocus($v); title("Root Locus"); grid on;\n'
                        'subplot(2, 2, 4); impulse(sys_active); title("Impulse Response"); grid on;\n'
                        'damp(sys_active);',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                UiButton(
                  label: 'Insert Script',
                  icon: LucideIcons.filePlus2,
                  variant: UiButtonVariant.secondary,
                  onPressed: () {
                    final pre = _buildControlSystemPreamble();
                    _insertCode(
                      '%% Control Systems Analysis\n'
                      '$pre\n'
                      'damp(sys_active);\n'
                      'figure;\n'
                      'subplot(2, 1, 1); step(sys_active); title("Closed-Loop Step Response"); grid on;\n'
                      'subplot(2, 1, 2); rlocus($v); title("Open-Loop Root Locus"); grid on;\n',
                      suggestedName: 'Control_Design.m',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. SIGNAL PROCESSING & FILTER DESIGNER
  // ===========================================================================
  String _buildFilterDesignCode() {
    final fs = double.tryParse(_fsCtrl.text.trim()) ?? 1000.0;
    final nyq = fs / 2.0;
    final fc1 = (double.tryParse(_fc1Ctrl.text.trim()) ?? 120.0).clamp(1.0, nyq * 0.98);
    final fc2 = (double.tryParse(_fc2Ctrl.text.trim()) ?? 250.0).clamp(fc1 + 1.0, nyq * 0.99);
    final rp = double.tryParse(_rippleCtrl.text.trim()) ?? 1.0;
    final isBand = _filterType == 'bandpass' || _filterType == 'stop';
    final wnStr = isBand
        ? '[${(fc1 / nyq).toStringAsFixed(4)}, ${(fc2 / nyq).toStringAsFixed(4)}]'
        : (fc1 / nyq).toStringAsFixed(4);

    String filterCall;
    switch (_filterFamily) {
      case 'cheby1':
        filterCall = '[b_filt, a_filt] = cheby1($_filterOrder, $rp, $wnStr, "$_filterType");';
        break;
      case 'cheby2':
        filterCall = '[b_filt, a_filt] = cheby2($_filterOrder, ${rp * 20}, $wnStr, "$_filterType");';
        break;
      case 'ellip':
        filterCall = '[b_filt, a_filt] = ellip($_filterOrder, $rp, ${rp * 30}, $wnStr, "$_filterType");';
        break;
      case 'fir1':
        filterCall = 'b_filt = fir1(${_filterOrder * 6}, $wnStr, "$_filterType");\na_filt = 1;';
        break;
      case 'butter':
      default:
        filterCall = '[b_filt, a_filt] = butter($_filterOrder, $wnStr, "$_filterType");';
        break;
    }

    return 'fs = $fs;\n$filterCall';
  }

  Widget _buildSignalStudio(UiTheme ui) {
    final isBand = _filterType == 'bandpass' || _filterType == 'stop';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          ui,
          title: 'Digital IIR / FIR Filter Designer',
          icon: LucideIcons.activity,
          children: [
            _dropdownRow(
              ui,
              label: 'Architecture',
              value: _filterFamily,
              items: const ['butter', 'cheby1', 'cheby2', 'ellip', 'fir1'],
              onChanged: (v) => setState(() => _filterFamily = v!),
            ),
            const SizedBox(height: 6),
            _dropdownRow(
              ui,
              label: 'Response',
              value: _filterType,
              items: const ['low', 'high', 'bandpass', 'stop'],
              onChanged: (v) => setState(() => _filterType = v!),
            ),
            const SizedBox(height: 6),
            _sliderRow(
              ui,
              'Order N ($_filterOrder)',
              _filterOrder.toDouble(),
              1,
              10,
              (v) => setState(() => _filterOrder = v.round()),
            ),
            Row(
              children: [
                Expanded(child: _labeledField(ui, 'Fs (Hz)', _fsCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _labeledField(ui, isBand ? 'Fc1 (Hz)' : 'Cutoff Fc (Hz)', _fc1Ctrl)),
                if (isBand) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _labeledField(ui, 'Fc2 (Hz)', _fc2Ctrl)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChipButton(ui, 'Plot Frequency Response (freqz)', LucideIcons.lineChart, () {
                  final code = _buildFilterDesignCode();
                  _runCode('$code\nfigure;\nfreqz(b_filt, a_filt, 1024, fs);\ntitle("Filter Frequency & Phase Response ($_filterFamily - $_filterType)");');
                }),
                _actionChipButton(ui, 'Apply to Noisy Signal & FFT', LucideIcons.waves, () {
                  final code = _buildFilterDesignCode();
                  _runCode(
                    '$code\n'
                    't = linspace(0, 1, fs);\n'
                    'x_clean = sin(2*pi*50*t) + 0.8*sin(2*pi*280*t);\n'
                    'x_noisy = x_clean + 0.4*randn(size(t));\n'
                    'y_filt = filtfilt(b_filt, a_filt, x_noisy);\n'
                    'figure;\n'
                    'subplot(2, 1, 1);\n'
                    'plot(t(1:250), x_noisy(1:250), "b", t(1:250), y_filt(1:250), "r");\n'
                    'title("Time Domain: Noisy Input vs Filtered Output");\n'
                    'xlabel("Time (s)"); ylabel("Amplitude"); legend("Noisy", "Filtered"); grid on;\n'
                    'subplot(2, 1, 2);\n'
                    'N_fft = length(t);\n'
                    'f_axis = linspace(0, fs/2, floor(N_fft/2));\n'
                    'X_mag = abs(fft(x_noisy)) / N_fft;\n'
                    'Y_mag = abs(fft(y_filt)) / N_fft;\n'
                    'plot(f_axis, 2*X_mag(1:floor(N_fft/2)), "b", f_axis, 2*Y_mag(1:floor(N_fft/2)), "r");\n'
                    'title("Single-Sided Amplitude Spectrum (FFT)");\n'
                    'xlabel("Frequency (Hz)"); ylabel("|X(f)|"); legend("Input FFT", "Filtered FFT"); grid on;',
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            UiButton(
              label: 'Insert Filter Design Script',
              icon: LucideIcons.filePlus2,
              variant: UiButtonVariant.secondary,
              onPressed: () {
                final code = _buildFilterDesignCode();
                _insertCode(
                  '%% Digital Filter Design ($_filterFamily - $_filterType)\n'
                  '$code\n'
                  'figure;\n'
                  'freqz(b_filt, a_filt, 1024, fs);\n',
                  suggestedName: 'Filter_Design.m',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionCard(
          ui,
          title: 'Spectral, PSD & Time-Frequency Analyzer',
          icon: LucideIcons.radio,
          children: [
            _dropdownRow(
              ui,
              label: 'Signal Source',
              value: _testWaveform,
              items: const [
                'Multi-Tone + Noise',
                'Linear Chirp Sweep',
                'Square / PWM Harmonics',
                'AM/FM Modulated Carrier',
              ],
              onChanged: (v) => setState(() => _testWaveform = v!),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChipButton(ui, 'FFT + Welch PSD', LucideIcons.chartBar, () {
                  final sigCode = _buildWaveformCode();
                  _runCode(
                    '$sigCode\n'
                    'figure;\n'
                    'subplot(2, 1, 1); plot(t(1:300), x_sig(1:300)); title("Signal Waveform ($_testWaveform)"); xlabel("Time (s)"); grid on;\n'
                    'subplot(2, 1, 2); pwelch(x_sig, 256, 128, 512, fs); title("Welch Power Spectral Density"); grid on;',
                  );
                }),
                _actionChipButton(ui, 'Spectrogram', LucideIcons.flame, () {
                  final sigCode = _buildWaveformCode();
                  _runCode(
                    '$sigCode\n'
                    'figure;\n'
                    'spectrogram(x_sig, 128, 120, 256, fs);\n'
                    'title("Time-Frequency Spectrogram ($_testWaveform)");',
                  );
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _buildWaveformCode() {
    final fs = double.tryParse(_fsCtrl.text.trim()) ?? 1000.0;
    switch (_testWaveform) {
      case 'Linear Chirp Sweep':
        return 'fs = $fs;\nt = linspace(0, 2, 2*fs);\nx_sig = chirp(t, 20, 2, 350);';
      case 'Square / PWM Harmonics':
        return 'fs = $fs;\nt = linspace(0, 1, fs);\nx_sig = square(2*pi*40*t) + 0.15*randn(size(t));';
      case 'AM/FM Modulated Carrier':
        return 'fs = $fs;\nt = linspace(0, 1, fs);\nx_sig = (1 + 0.6*cos(2*pi*15*t)) .* sin(2*pi*180*t + 2*sin(2*pi*8*t));';
      case 'Multi-Tone + Noise':
      default:
        return 'fs = $fs;\nt = linspace(0, 1, fs);\nx_sig = sin(2*pi*60*t) + 0.7*sin(2*pi*180*t) + 0.4*cos(2*pi*320*t) + 0.35*randn(size(t));';
    }
  }

  // ===========================================================================
  // 3. MATRIX & LINEAR ALGEBRA LAB
  // ===========================================================================
  Widget _buildMatrixStudio(UiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          ui,
          title: 'Matrix A & Right-Hand Side Vector b',
          icon: LucideIcons.grid3x3,
          children: [
            _labeledField(ui, 'Matrix A', _matACtrl),
            const SizedBox(height: 8),
            _labeledField(ui, 'Vector b (for Ax = b)', _vecBCtrl),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _presetChip(ui, '3x3 SPD Tridiagonal', () {
                  setState(() {
                    _matACtrl.text = '[4, -1, 0; -1, 4, -1; 0, -1, 4]';
                    _vecBCtrl.text = '[15; 10; 15]';
                  });
                }),
                _presetChip(ui, '3x3 Coupled Oscillators', () {
                  setState(() {
                    _matACtrl.text = '[2, -1, 0; -1, 3, -1; 0, -1, 2]';
                    _vecBCtrl.text = '[1; 0; 1]';
                  });
                }),
                _presetChip(ui, '4x4 Magic Square', () {
                  setState(() {
                    _matACtrl.text = 'magic(4)';
                    _vecBCtrl.text = '[34; 34; 34; 34]';
                  });
                }),
                _presetChip(ui, '4x4 Hilbert (Ill-Conditioned)', () {
                  setState(() {
                    _matACtrl.text = 'hilb(4)';
                    _vecBCtrl.text = 'ones(4, 1)';
                  });
                }),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChipButton(ui, 'Solve Ax = b', LucideIcons.check, () {
                  final a = _matACtrl.text.trim();
                  final b = _vecBCtrl.text.trim();
                  _runCode(
                    'A = $a;\nb = $b;\nx_sol = A \\ b;\n'
                    'disp("=== Linear System Solution x = A \\ b ===");\ndisp(x_sol);\n'
                    'residual_norm = norm(A * x_sol - b);\n'
                    'fprintf("Residual ||Ax - b||_2 = %.3e\\n", residual_norm);',
                  );
                }),
                _actionChipButton(ui, 'Eigenvalues & Plot', LucideIcons.sparkles, () {
                  final a = _matACtrl.text.trim();
                  _runCode(
                    'A = $a;\n[V_eig, D_eig] = eig(A);\neig_vals = diag(D_eig);\n'
                    'disp("=== Eigenvalues of A ===");\ndisp(eig_vals);\n'
                    'figure;\nplot(real(eig_vals), imag(eig_vals), "ro");\n'
                    'xlabel("Real Axis"); ylabel("Imaginary Axis");\n'
                    'title("Eigenvalue Spectrum of Matrix A"); grid on;',
                  );
                }),
                _actionChipButton(ui, 'SVD Spectrum', LucideIcons.barChart3, () {
                  final a = _matACtrl.text.trim();
                  _runCode(
                    'A = $a;\n[U_svd, S_svd, V_svd] = svd(A);\nsing_vals = diag(S_svd);\n'
                    'disp("=== Singular Values of A ===");\ndisp(sing_vals);\n'
                    'figure;\nstem(sing_vals);\n'
                    'title("Singular Value Decomposition (SVD) Spectrum");\n'
                    'xlabel("Index"); ylabel("Singular Value \\sigma_i"); grid on;',
                  );
                }),
                _actionChipButton(ui, 'LU & QR Factors', LucideIcons.layers, () {
                  final a = _matACtrl.text.trim();
                  _runCode(
                    'A = $a;\n[L_mat, U_mat] = lu(A);\n[Q_mat, R_mat] = qr(A);\n'
                    'disp("=== LU Decomposition (L, U) ===");\ndisp(L_mat);\ndisp(U_mat);\n'
                    'disp("=== QR Decomposition (Q, R) ===");\ndisp(Q_mat);\ndisp(R_mat);',
                  );
                }),
                _actionChipButton(ui, 'Full Matrix Diagnostics', LucideIcons.microscope, () {
                  final a = _matACtrl.text.trim();
                  _runCode(
                    'A = $a;\n'
                    'fprintf("Size: %dx%d\\n", size(A, 1), size(A, 2));\n'
                    'fprintf("Rank: %d\\n", rank(A));\n'
                    'fprintf("Determinant: %.6g\\n", det(A));\n'
                    'fprintf("Trace: %.6g\\n", trace(A));\n'
                    'fprintf("2-Norm: %.6g\\n", norm(A));\n'
                    'fprintf("Condition Number: %.6g\\n", cond(A));\n'
                    'A_inv = pinv(A);\ndisp("Pseudoinverse / Inverse:");\ndisp(A_inv);',
                  );
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. ODE SOLVER & NUMERICAL METHODS LAB
  // ===========================================================================
  Widget _buildOdeStudio(UiTheme ui) {
    String p1Label = 'Mass m (kg)';
    String p2Label = 'Damping c (N·s/m)';
    String p3Label = 'Stiffness k (N/m)';
    if (_odePreset == 'RLC Series Circuit') {
      p1Label = 'Resistance R (Ω)';
      p2Label = 'Inductance L (H)';
      p3Label = 'Capacitance C (F)';
    } else if (_odePreset == 'Van der Pol Oscillator') {
      p1Label = 'Nonlinearity μ';
      p2Label = 'Initial x(0)';
      p3Label = 'Initial dx/dt(0)';
    } else if (_odePreset == 'Lorenz 3D Attractor') {
      p1Label = 'Sigma σ';
      p2Label = 'Rho ρ';
      p3Label = 'Beta β';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          ui,
          title: 'ODE45 Dynamical Systems Simulator',
          icon: LucideIcons.sigma,
          children: [
            _dropdownRow(
              ui,
              label: 'System Model',
              value: _odePreset,
              items: const [
                'Mass-Spring-Damper',
                'RLC Series Circuit',
                'Van der Pol Oscillator',
                'Lorenz 3D Attractor',
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _odePreset = v;
                  if (v == 'Mass-Spring-Damper') {
                    _odeParam1Ctrl.text = '1.0';
                    _odeParam2Ctrl.text = '0.4';
                    _odeParam3Ctrl.text = '4.0';
                    _odeTmaxCtrl.text = '20';
                  } else if (v == 'RLC Series Circuit') {
                    _odeParam1Ctrl.text = '2.0';
                    _odeParam2Ctrl.text = '0.5';
                    _odeParam3Ctrl.text = '0.05';
                    _odeTmaxCtrl.text = '8';
                  } else if (v == 'Van der Pol Oscillator') {
                    _odeParam1Ctrl.text = '1.5';
                    _odeParam2Ctrl.text = '2.0';
                    _odeParam3Ctrl.text = '0.0';
                    _odeTmaxCtrl.text = '25';
                  } else if (v == 'Lorenz 3D Attractor') {
                    _odeParam1Ctrl.text = '10.0';
                    _odeParam2Ctrl.text = '28.0';
                    _odeParam3Ctrl.text = '2.667';
                    _odeTmaxCtrl.text = '30';
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _labeledField(ui, p1Label, _odeParam1Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: _labeledField(ui, p2Label, _odeParam2Ctrl)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _labeledField(ui, p3Label, _odeParam3Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: _labeledField(ui, 'Sim Time T_end (s)', _odeTmaxCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: UiButton(
                    label: 'Simulate & Plot ODE',
                    icon: LucideIcons.play,
                    variant: UiButtonVariant.primary,
                    onPressed: () => _runCode(_generateOdeScript()),
                  ),
                ),
                const SizedBox(width: 8),
                UiButton(
                  label: 'Insert ODE Script',
                  icon: LucideIcons.filePlus2,
                  variant: UiButtonVariant.secondary,
                  onPressed: () => _insertCode(
                    _generateOdeScript(),
                    suggestedName: 'ODE_Simulation.m',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionCard(
          ui,
          title: 'Polynomial & Root Solver',
          icon: LucideIcons.functionSquare,
          children: [
            _labeledField(ui, 'Polynomial Coefficients p(x)', _polyCtrl),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChipButton(ui, 'Find Roots & Plot p(x)', LucideIcons.radical, () {
                  final pStr = _polyCtrl.text.trim();
                  _runCode(
                    'p_coeff = $pStr;\n'
                    'r_poly = roots(p_coeff);\n'
                    'disp("=== Polynomial Roots ===");\ndisp(r_poly);\n'
                    'dp_coeff = polyder(p_coeff);\n'
                    'x_grid = linspace(min(real(r_poly)) - 1.5, max(real(r_poly)) + 1.5, 400);\n'
                    'y_grid = polyval(p_coeff, x_grid);\n'
                    'figure;\nplot(x_grid, y_grid, "b", real(r_poly), zeros(size(r_poly)), "ro");\n'
                    'title("Polynomial Curve & Real Roots"); xlabel("x"); ylabel("p(x)"); grid on;',
                  );
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _generateOdeScript() {
    final p1 = double.tryParse(_odeParam1Ctrl.text.trim()) ?? 1.0;
    final p2 = double.tryParse(_odeParam2Ctrl.text.trim()) ?? 0.4;
    final p3 = double.tryParse(_odeParam3Ctrl.text.trim()) ?? 4.0;
    final tmax = double.tryParse(_odeTmaxCtrl.text.trim()) ?? 20.0;

    if (_odePreset == 'Lorenz 3D Attractor') {
      return '%% Lorenz Chaotic Attractor (ODE45)\n'
          'sigma = $p1; rho = $p2; beta = $p3;\n'
          'f_lorenz = @(t, y) [sigma*(y(2) - y(1)); y(1)*(rho - y(3)) - y(2); y(1)*y(2) - beta*y(3)];\n'
          '[t_ode, y_ode] = ode45(f_lorenz, [0, $tmax], [1; 1; 1]);\n'
          'figure;\n'
          'plot3(y_ode(:,1), y_ode(:,2), y_ode(:,3));\n'
          'title("Lorenz 3D Chaotic Attractor");\n'
          'xlabel("x"); ylabel("y"); zlabel("z"); grid on;';
    } else if (_odePreset == 'Van der Pol Oscillator') {
      return '%% Van der Pol Nonlinear Oscillator (ODE45)\n'
          'mu = $p1;\n'
          'f_vdp = @(t, y) [y(2); mu*(1 - y(1)^2)*y(2) - y(1)];\n'
          '[t_ode, y_ode] = ode45(f_vdp, [0, $tmax], [$p2; $p3]);\n'
          'figure;\n'
          'subplot(2, 1, 1); plot(t_ode, y_ode(:,1), "b", t_ode, y_ode(:,2), "r");\n'
          'title("Van der Pol Time Response (\\mu = $p1)"); xlabel("Time (s)"); legend("x(t)", "dx/dt"); grid on;\n'
          'subplot(2, 1, 2); plot(y_ode(:,1), y_ode(:,2));\n'
          'title("Limit Cycle Phase Portrait"); xlabel("x"); ylabel("dx/dt"); grid on;';
    } else if (_odePreset == 'RLC Series Circuit') {
      return '%% RLC Series Circuit Step Transient\n'
          'R_val = $p1; L_val = $p2; C_val = $p3; V_in = 12;\n'
          'G_rlc = tf([1], [L_val*C_val, R_val*C_val, 1]);\n'
          't_rlc = linspace(0, $tmax, 600);\n'
          '[v_cap, t_out] = step(V_in * G_rlc, t_rlc);\n'
          'figure;\n'
          'plot(t_out, v_cap);\n'
          'title("RLC Capacitor Voltage Step Response (R=$p1\\Omega, L=${p2}H, C=${p3}F)");\n'
          'xlabel("Time (s)"); ylabel("Vc (V)"); grid on;';
    } else {
      return '%% Mass-Spring-Damper Dynamical System (ODE45)\n'
          'm = $p1; c = $p2; k = $p3;\n'
          'f_msd = @(t, y) [y(2); (1.0 - c*y(2) - k*y(1)) / m];\n'
          '[t_ode, y_ode] = ode45(f_msd, [0, $tmax], [0; 0]);\n'
          'figure;\n'
          'subplot(2, 1, 1); plot(t_ode, y_ode(:,1), "b", t_ode, y_ode(:,2), "r");\n'
          'title("Mass-Spring-Damper Response (m=$p1, c=$p2, k=$p3)");\n'
          'xlabel("Time (s)"); legend("Displacement x(t)", "Velocity v(t)"); grid on;\n'
          'subplot(2, 1, 2); plot(y_ode(:,1), y_ode(:,2));\n'
          'title("Phase Plane Trajectory (x vs v)"); xlabel("x (m)"); ylabel("v (m/s)"); grid on;';
    }
  }

  // ===========================================================================
  // 5. UNIT CONVERTER & PHYSICAL CONSTANTS
  // ===========================================================================
  Widget _buildUnitsStudio(UiTheme ui) {
    final val = double.tryParse(_unitInputCtrl.text.trim()) ?? 0.0;
    final conversions = _computeConversions(_unitCategory, val);

    final lVal = double.tryParse(_lcLValCtrl.text.trim()) ?? 1e-3;
    final cVal = double.tryParse(_lcCValCtrl.text.trim()) ?? 1e-6;
    final f0 = (lVal > 0 && cVal > 0) ? 1.0 / (2 * math.pi * math.sqrt(lVal * cVal)) : 0.0;
    final zChar = (lVal > 0 && cVal > 0) ? math.sqrt(lVal / cVal) : 0.0;

    const constants = <Map<String, String>>[
      {'sym': 'c0', 'name': 'Speed of Light', 'val': '299792458', 'unit': 'm/s'},
      {'sym': 'g0', 'name': 'Standard Gravity', 'val': '9.80665', 'unit': 'm/s^2'},
      {'sym': 'h_planck', 'name': 'Planck Constant', 'val': '6.62607015e-34', 'unit': 'J·s'},
      {'sym': 'k_B', 'name': 'Boltzmann Constant', 'val': '1.380649e-23', 'unit': 'J/K'},
      {'sym': 'eps0', 'name': 'Vacuum Permittivity', 'val': '8.8541878128e-12', 'unit': 'F/m'},
      {'sym': 'mu0', 'name': 'Vacuum Permeability', 'val': '1.25663706212e-6', 'unit': 'H/m'},
      {'sym': 'q_e', 'name': 'Elementary Charge', 'val': '1.602176634e-19', 'unit': 'C'},
      {'sym': 'R_gas', 'name': 'Universal Gas Constant', 'val': '8.314462618', 'unit': 'J/(mol·K)'},
      {'sym': 'Z0', 'name': 'Free-Space Impedance', 'val': '376.730313668', 'unit': 'Ω'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          ui,
          title: 'Interactive Engineering Unit Converter',
          icon: LucideIcons.arrowLeftRight,
          children: [
            _dropdownRow(
              ui,
              label: 'Quantity',
              value: _unitCategory,
              items: const ['Frequency', 'Gain / Power', 'Angle', 'Pressure', 'Temperature'],
              onChanged: (v) => setState(() => _unitCategory = v!),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _unitInputCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Input Value ($_unitCategory)',
                labelStyle: TextStyle(color: ui.colors.textMuted, fontSize: 11),
                isDense: true,
                filled: true,
                fillColor: ui.colors.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            ...conversions.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    UiText(text: e.key, variant: UiTextVariant.caption, color: ui.colors.textMuted),
                    SelectableText(
                      e.value,
                      style: ui.typography.codeBody.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ui.colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionCard(
          ui,
          title: 'LC Resonance & Impedance Calculator',
          icon: LucideIcons.cpu,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lcLValCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Inductance L (H)',
                      labelStyle: TextStyle(color: ui.colors.textMuted, fontSize: 11),
                      isDense: true,
                      filled: true,
                      fillColor: ui.colors.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lcCValCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: ui.colors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Capacitance C (F)',
                      labelStyle: TextStyle(color: ui.colors.textMuted, fontSize: 11),
                      isDense: true,
                      filled: true,
                      fillColor: ui.colors.canvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            UiText(
              text: 'Resonant f0 = ${f0.toStringAsFixed(2)} Hz (${(2 * math.pi * f0).toStringAsFixed(2)} rad/s) • Z_c = ${zChar.toStringAsFixed(2)} Ω',
              variant: UiTextVariant.codeBody,
              fontSize: 11,
              color: ui.colors.accent,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionCard(
          ui,
          title: 'SI & Engineering Constants (Click to Inject)',
          icon: LucideIcons.compass,
          children: [
            ...constants.map(
              (c) => InkWell(
                onTap: () {
                  final line = '${c['sym']} = ${c['val']}; % ${c['name']} (${c['unit']})';
                  _insertCode(line);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 68,
                        child: UiText(
                          text: c['sym']!,
                          variant: UiTextVariant.codeBody,
                          fontWeight: FontWeight.bold,
                          color: ui.colors.accent,
                        ),
                      ),
                      Expanded(
                        child: UiText(
                          text: c['name']!,
                          variant: UiTextVariant.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      UiText(
                        text: '${c['val']} ${c['unit']}',
                        variant: UiTextVariant.codeBody,
                        fontSize: 10,
                        color: ui.colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            UiButton(
              label: 'Load All SI Constants into Workspace',
              icon: LucideIcons.download,
              variant: UiButtonVariant.secondary,
              onPressed: () {
                final script = constants.map((c) => '${c['sym']} = ${c['val']};').join('\n');
                _runCode('$script\ndisp("Loaded all SI physical constants into workspace.");');
              },
            ),
          ],
        ),
      ],
    );
  }

  Map<String, String> _computeConversions(String category, double v) {
    switch (category) {
      case 'Frequency':
        return {
          'f (Hz) → ω (rad/s)': '${(2 * math.pi * v).toStringAsFixed(4)} rad/s',
          'f (Hz) → RPM': '${(v * 60.0).toStringAsFixed(2)} RPM',
          'ω (rad/s) → f (Hz)': '${(v / (2 * math.pi)).toStringAsFixed(4)} Hz',
          'Period T (from Hz)': v != 0 ? '${(1.0 / v).toStringAsExponential(4)} s' : '∞',
        };
      case 'Gain / Power':
        return {
          'Amplitude Ratio → dB (20·log10)':
              v > 0 ? '${(20 * math.log(v) / math.ln10).toStringAsFixed(3)} dB' : '-∞ dB',
          'Power Ratio → dB (10·log10)':
              v > 0 ? '${(10 * math.log(v) / math.ln10).toStringAsFixed(3)} dB' : '-∞ dB',
          'dB → Amplitude Ratio (10^(dB/20))':
              math.pow(10.0, v / 20.0).toStringAsFixed(5),
          'Watts → dBm':
              v > 0 ? '${(10 * math.log(v * 1000.0) / math.ln10).toStringAsFixed(3)} dBm' : '-∞ dBm',
        };
      case 'Angle':
        return {
          'Degrees → Radians': '${(v * math.pi / 180.0).toStringAsFixed(6)} rad',
          'Radians → Degrees': '${(v * 180.0 / math.pi).toStringAsFixed(4)}°',
        };
      case 'Pressure':
        return {
          'kPa → bar': '${(v / 100.0).toStringAsFixed(4)} bar',
          'kPa → psi': '${(v * 0.1450377).toStringAsFixed(4)} psi',
          'bar → psi': '${(v * 14.50377).toStringAsFixed(3)} psi',
          'atm → kPa': '${(v * 101.325).toStringAsFixed(3)} kPa',
        };
      case 'Temperature':
      default:
        return {
          '°C → Kelvin (K)': '${(v + 273.15).toStringAsFixed(2)} K',
          '°C → Fahrenheit (°F)': '${(v * 9.0 / 5.0 + 32.0).toStringAsFixed(2)} °F',
          'K → °C': '${(v - 273.15).toStringAsFixed(2)} °C',
        };
    }
  }

  // ===========================================================================
  // 6. ENGINEERING TEMPLATES & BLUEPRINTS
  // ===========================================================================
  Widget _buildTemplatesStudio(UiTheme ui) {
    final templates = <Map<String, String>>[
      {
        'title': 'PID Control Loop & Stability Margin Suite',
        'file': 'PID_Control_Suite.m',
        'desc': 'Plant transfer function, PID controller, closed-loop step, Bode margins & Root Locus.',
        'code': '''%% PID Control Loop & Stability Margin Suite
clear; clc; close all;

% 1. Define Plant G(s) and PID Controller C(s)
G = tf([20], conv([1, 1], [1, 4, 10]));
C = pid(2.5, 1.8, 0.45);

% 2. Open-loop and Closed-loop Systems
L = series(C, G);
T = feedback(L, 1);

disp("=== Closed-Loop Poles & Damping ===");
damp(T);

% 3. Plot Dashboard
figure;
subplot(2, 2, 1); step(T); title("Closed-Loop Step Response"); grid on;
subplot(2, 2, 2); pzmap(T); title("Closed-Loop Pole-Zero Map"); grid on;
subplot(2, 2, 3); rlocus(G); title("Plant Root Locus"); grid on;
subplot(2, 2, 4); impulse(T); title("Closed-Loop Impulse Response"); grid on;
''',
      },
      {
        'title': 'Digital Filter Bank & Spectral Analysis',
        'file': 'Filter_Spectral_Lab.m',
        'desc': 'Butterworth & Chebyshev filter design, zero-phase filtering, FFT & Welch PSD.',
        'code': '''%% Digital Filter Bank & Spectral Analysis
clear; clc; close all;

fs = 1000;
t = linspace(0, 1, fs);

% Composite signal: 50 Hz + 220 Hz + Gaussian noise
x_clean = sin(2*pi*50*t) + 0.75*sin(2*pi*220*t);
x_noisy = x_clean + 0.45*randn(size(t));

% 4th-order Butterworth Lowpass at 100 Hz
[b, a] = butter(4, 100/(fs/2), "low");
y_filt = filtfilt(b, a, x_noisy);

figure;
subplot(2, 1, 1);
plot(t(1:250), x_noisy(1:250), "b", t(1:250), y_filt(1:250), "r");
title("Zero-Phase Butterworth Filtering (fc = 100 Hz)");
xlabel("Time (s)"); ylabel("Amplitude"); legend("Noisy", "Filtered"); grid on;

subplot(2, 1, 2);
pwelch(x_noisy, 256, 128, 512, fs);
title("Power Spectral Density (Welch)"); grid on;
''',
      },
      {
        'title': 'Three-Phase Electrical Power & Harmonics',
        'file': 'Three_Phase_Power.m',
        'desc': 'Balanced 3-phase voltages, harmonic distortion analysis, and Clarke α-β transform.',
        'code': '''%% Three-Phase Power System & Clarke Transform Analysis
clear; clc; close all;

f = 50; % 50 Hz Grid
fs = 5000;
t = linspace(0, 0.06, 300);
w = 2*pi*f;

% Three-phase voltages with 5th and 7th harmonics
va = 325*sin(w*t) + 25*sin(5*w*t) + 15*sin(7*w*t);
vb = 325*sin(w*t - 2*pi/3) + 25*sin(5*(w*t - 2*pi/3)) + 15*sin(7*(w*t - 2*pi/3));
vc = 325*sin(w*t + 2*pi/3) + 25*sin(5*(w*t + 2*pi/3)) + 15*sin(7*(w*t + 2*pi/3));

% Clarke Stationary Frame (alpha-beta)
v_alpha = (2/3) * (va - 0.5*vb - 0.5*vc);
v_beta  = (2/3) * (sqrt(3)/2 * (vb - vc));

figure;
subplot(2, 1, 1);
plot(t*1000, va, "r", t*1000, vb, "g", t*1000, vc, "b");
title("Three-Phase Line-to-Neutral Voltages (with 5th & 7th Harmonics)");
xlabel("Time (ms)"); ylabel("Voltage (V)"); legend("Va", "Vb", "Vc"); grid on;

subplot(2, 1, 2);
plot(v_alpha, v_beta);
title("Clarke Transform Space Vector Locus (V_\\alpha vs V_\\beta)");
xlabel("V_\\alpha (V)"); ylabel("V_\\beta (V)"); axis equal; grid on;
''',
      },
      {
        'title': '3D Surface, Mesh & Parametric Helix Lab',
        'file': 'Surface_3D_Lab.m',
        'desc': '3D sinc wave surface, damped Gaussian mesh, and 3D phase-space spiral.',
        'code': '''%% 3D Surface & Parametric Trajectory Lab
clear; clc; close all;

[X, Y] = meshgrid(linspace(-6, 6, 45), linspace(-6, 6, 45));
R = sqrt(X.^2 + Y.^2) + eps;
Z = sin(R) ./ R;

figure;
surf(X, Y, Z);
title("3D Radial Sinc Surface: sin(R)/R");
xlabel("X"); ylabel("Y"); zlabel("Z");
colorbar;
''',
      },
      {
        'title': '2-DOF Mechanical Vibration Modal Analysis',
        'file': 'Modal_Vibration_2DOF.m',
        'desc': 'Natural frequencies, mode shapes, and harmonic forced response of a 2-DOF system.',
        'code': '''%% 2-DOF Mechanical Vibration Modal Analysis
clear; clc; close all;

m1 = 2.0; m2 = 1.0;
k1 = 80.0; k2 = 40.0;

M = [m1, 0; 0, m2];
K = [k1 + k2, -k2; -k2, k2];

% Solve Generalized Eigenvalue Problem: M^-1 * K
[ModeShapes, Lambda] = eig(inv(M) * K);
omega_n = sqrt(diag(Lambda));
freq_hz = omega_n / (2*pi);

disp("=== Natural Frequencies (rad/s) ===");
disp(omega_n);
disp("=== Natural Frequencies (Hz) ===");
disp(freq_hz);
disp("=== Mode Shapes Matrix ===");
disp(ModeShapes);

% Frequency Response Function H11(jw)
w_sweep = linspace(0.1, 12, 400);
H11 = zeros(size(w_sweep));
for idx = 1:length(w_sweep)
    w = w_sweep(idx);
    Z_dyn = K - (w^2)*M + 1j*0.4*w*eye(2);
    u_resp = Z_dyn \\ [1; 0];
    H11(idx) = abs(u_resp(1));
end

figure;
semilogy(w_sweep, H11);
title("2-DOF Receptance Frequency Response |H_{11}(j\\omega)|");
xlabel("Excitation Frequency \\omega (rad/s)"); ylabel("Amplitude (m/N)"); grid on;
''',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: templates.map((tpl) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _sectionCard(
            ui,
            title: tpl['title']!,
            icon: LucideIcons.fileCode2,
            children: [
              UiText(
                text: tpl['desc']!,
                variant: UiTextVariant.caption,
                color: ui.colors.textMuted,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: UiButton(
                      label: 'Run Now',
                      icon: LucideIcons.play,
                      variant: UiButtonVariant.primary,
                      size: UiButtonSize.sm,
                      onPressed: () => _runCode(tpl['code']!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: UiButton(
                      label: 'Open in Editor',
                      icon: LucideIcons.fileEdit,
                      variant: UiButtonVariant.secondary,
                      size: UiButtonSize.sm,
                      onPressed: () => _insertCode(
                        tpl['code']!,
                        suggestedName: tpl['file'],
                        replaceAll: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // SHARED UI BUILDING BLOCKS
  // ===========================================================================
  Widget _sectionCard(
    UiTheme ui, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ui.colors.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ui.colors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: ui.colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: UiText(
                  text: title,
                  variant: UiTextVariant.label,
                  fontWeight: FontWeight.bold,
                  color: ui.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _labeledField(
    UiTheme ui,
    String label,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(text: label, variant: UiTextVariant.caption, color: ui.colors.textMuted),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: ui.typography.codeBody.copyWith(color: ui.colors.textPrimary, fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: ui.colors.panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: ui.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: ui.colors.border.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: ui.colors.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownRow(
    UiTheme ui, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UiText(text: label, variant: UiTextVariant.caption, color: ui.colors.textMuted),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: ui.colors.panel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ui.colors.border.withValues(alpha: 0.6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: ui.colors.panel,
              style: ui.typography.body.copyWith(color: ui.colors.textPrimary, fontSize: 11),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sliderRow(
    UiTheme ui,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: UiText(
            text: label,
            variant: UiTextVariant.caption,
            color: ui.colors.textSecondary,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: ui.colors.accent,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: UiText(
            text: value.toStringAsFixed(2),
            variant: UiTextVariant.codeBody,
            fontSize: 11,
            color: ui.colors.accent,
          ),
        ),
      ],
    );
  }

  Widget _presetChip(UiTheme ui, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ui.colors.panel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ui.colors.divider.withValues(alpha: 0.6)),
        ),
        child: UiText(
          text: label,
          variant: UiTextVariant.caption,
          fontSize: 10,
          color: ui.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _actionChipButton(
    UiTheme ui,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ui.colors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ui.colors.accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: ui.colors.accent),
            const SizedBox(width: 5),
            UiText(
              text: label,
              variant: UiTextVariant.caption,
              fontWeight: FontWeight.w600,
              color: ui.colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
