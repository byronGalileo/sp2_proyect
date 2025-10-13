import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/managed_service.dart';
import '../../../dashboard/views/widgets/common/custom_button.dart';
import '../../../dashboard/views/widgets/common/custom_text_field.dart';
import '../../controllers/managed_services_controller.dart';

class ServiceFormDialog extends StatefulWidget {
  final ManagedService? service;
  final String? preselectedHostId;

  const ServiceFormDialog({
    super.key,
    this.service,
    this.preselectedHostId,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceIdController = TextEditingController();
  final _hostIdController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _dependenciesController = TextEditingController();

  // Monitoring fields
  final _intervalSecController = TextEditingController(text: '60');
  final _timeoutSecController = TextEditingController(text: '30');
  final _retryAttemptsController = TextEditingController(text: '3');
  final _retryDelaySecController = TextEditingController(text: '5');

  // Recovery fields
  final _maxRecoveryAttemptsController = TextEditingController(text: '3');
  final _recoveryCooldownSecController = TextEditingController(text: '300');
  final _customScriptController = TextEditingController();

  // Alerting fields
  final _alertChannelsController = TextEditingController();

  String? _selectedServiceType;
  String? _selectedHostId;
  String _selectedMonitoringMethod = 'ssh';
  bool _monitoringEnabled = true;
  bool _recoverOnDown = false;
  String _recoverAction = 'restart';
  bool _notifyBeforeRecovery = true;
  bool _alertingEnabled = true;
  String _alertSeverity = 'medium';

  bool get isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final service = widget.service!;
      _serviceIdController.text = service.serviceId;
      _selectedHostId = service.hostId;
      _serviceNameController.text = service.serviceName;
      _selectedServiceType = service.serviceType;
      _displayNameController.text = service.displayName ?? '';
      _descriptionController.text = service.description ?? '';
      _tagsController.text = service.tags.join(', ');
      _dependenciesController.text = service.dependencies.join(', ');

      // Monitoring
      _selectedMonitoringMethod = service.monitoring.method;
      _monitoringEnabled = service.monitoring.enabled;
      _intervalSecController.text = service.monitoring.intervalSec.toString();
      _timeoutSecController.text = service.monitoring.timeoutSec.toString();
      _retryAttemptsController.text = service.monitoring.retryAttempts.toString();
      _retryDelaySecController.text = service.monitoring.retryDelaySec.toString();

      // Recovery
      _recoverOnDown = service.recovery.recoverOnDown;
      _recoverAction = service.recovery.recoverAction;
      _customScriptController.text = service.recovery.customScript ?? '';
      _maxRecoveryAttemptsController.text = service.recovery.maxRecoveryAttempts.toString();
      _recoveryCooldownSecController.text = service.recovery.recoveryCooldownSec.toString();
      _notifyBeforeRecovery = service.recovery.notifyBeforeRecovery;

      // Alerting
      _alertingEnabled = service.alerting.enabled;
      _alertChannelsController.text = service.alerting.channels.join(', ');
      _alertSeverity = service.alerting.severity;
    } else {
      // Pre-select host if an ID is passed to the dialog
      _selectedHostId = widget.preselectedHostId;
    }
  }

  @override
  void dispose() {
    _serviceIdController.dispose();
    _hostIdController.dispose();
    _serviceNameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _dependenciesController.dispose();
    _intervalSecController.dispose();
    _timeoutSecController.dispose();
    _retryAttemptsController.dispose();
    _retryDelaySecController.dispose();
    _maxRecoveryAttemptsController.dispose();
    _recoveryCooldownSecController.dispose();
    _customScriptController.dispose();
    _alertChannelsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<ManagedServicesController>();

    // Parse tags and dependencies
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final dependencies = _dependenciesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final channels = _alertChannelsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Create monitoring, recovery, and alerting objects
    final monitoring = ServiceMonitoring(
      method: _selectedMonitoringMethod,
      enabled: _monitoringEnabled,
      intervalSec: int.tryParse(_intervalSecController.text) ?? 60,
      timeoutSec: int.tryParse(_timeoutSecController.text) ?? 30,
      retryAttempts: int.tryParse(_retryAttemptsController.text) ?? 3,
      retryDelaySec: int.tryParse(_retryDelaySecController.text) ?? 5,
    );

    final recovery = ServiceRecovery(
      recoverOnDown: _recoverOnDown,
      recoverAction: _recoverAction,
      customScript: _customScriptController.text.trim().isEmpty
          ? null
          : _customScriptController.text.trim(),
      maxRecoveryAttempts: int.tryParse(_maxRecoveryAttemptsController.text) ?? 3,
      recoveryCooldownSec: int.tryParse(_recoveryCooldownSecController.text) ?? 300,
      notifyBeforeRecovery: _notifyBeforeRecovery,
    );

    final alerting = ServiceAlerting(
      enabled: _alertingEnabled,
      channels: channels.isEmpty ? ['default'] : channels,
      severity: _alertSeverity,
    );

    // Get environment and region from the selected host
    final selectedHost = controller.getHostById(_selectedHostId!);
    if (selectedHost == null) {
      Get.snackbar(
        'Error',
        'Please select a valid host',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    bool success;
    if (isEditing) {
      success = await controller.updateService(
        serviceId: widget.service!.serviceId,
        hostId: _selectedHostId,
        serviceName: _serviceNameController.text.trim(),
        serviceType: _selectedServiceType,
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        environment: selectedHost.environment,
        region: selectedHost.region,
        monitoring: monitoring,
        recovery: recovery,
        alerting: alerting,
        tags: tags.isEmpty ? null : tags,
        dependencies: dependencies.isEmpty ? null : dependencies,
      );
    } else {
      success = await controller.createService(
        serviceId: _serviceIdController.text.trim(),
        hostId: _selectedHostId!,
        serviceName: _serviceNameController.text.trim(),
        serviceType: _selectedServiceType!,
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        environment: selectedHost.environment,
        region: selectedHost.region,
        monitoring: monitoring,
        recovery: recovery,
        alerting: alerting,
        tags: tags,
        dependencies: dependencies,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagedServicesController>();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.padding * 2),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        isEditing ? 'Edit Service' : 'Add New Service',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Basic Information Section
                  _buildSectionTitle(context, 'Basic Information'),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _serviceIdController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Service ID *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.fingerprint),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Service ID is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: _selectedHostId,
                              decoration: const InputDecoration(
                                labelText: 'Host *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.computer),
                              ),
                              items: controller.availableHosts
                                  .map((host) => DropdownMenuItem(
                                        value: host.hostId,
                                        child: Text('${host.hostname} (${host.hostId})'),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedHostId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Host is required';
                                }
                                return null;
                              },
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _serviceNameController,
                          label: 'Service Name *',
                          prefixIcon: Icons.dns,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Service Name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: _selectedServiceType,
                              decoration: const InputDecoration(
                                labelText: 'Service Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: controller.availableServiceTypes
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedServiceType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Service Type is required';
                                }
                                return null;
                              },
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    prefixIcon: Icons.label,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Monitoring Section
                  _buildSectionTitle(context, 'Monitoring Configuration'),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Enable Monitoring'),
                    value: _monitoringEnabled,
                    onChanged: (value) {
                      setState(() {
                        _monitoringEnabled = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedMonitoringMethod,
                    decoration: const InputDecoration(
                      labelText: 'Monitoring Method',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_input_antenna),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ssh', child: Text('SSH')),
                      DropdownMenuItem(value: 'http', child: Text('HTTP')),
                      DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMonitoringMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _intervalSecController,
                          decoration: const InputDecoration(
                            labelText: 'Interval (sec)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _timeoutSecController,
                          decoration: const InputDecoration(
                            labelText: 'Timeout (sec)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.hourglass_empty),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _retryAttemptsController,
                          decoration: const InputDecoration(
                            labelText: 'Retry Attempts',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.replay),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _retryDelaySecController,
                          decoration: const InputDecoration(
                            labelText: 'Retry Delay (sec)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recovery Section
                  _buildSectionTitle(context, 'Recovery Configuration'),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Auto-recover on Down'),
                    value: _recoverOnDown,
                    onChanged: (value) {
                      setState(() {
                        _recoverOnDown = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _recoverAction,
                    decoration: const InputDecoration(
                      labelText: 'Recovery Action',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'restart', child: Text('Restart')),
                      DropdownMenuItem(value: 'start', child: Text('Start')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom Script')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _recoverAction = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_recoverAction == 'custom')
                    TextFormField(
                      controller: _customScriptController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Recovery Script',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      maxLines: 3,
                    ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxRecoveryAttemptsController,
                          decoration: const InputDecoration(
                            labelText: 'Max Recovery Attempts',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _recoveryCooldownSecController,
                          decoration: const InputDecoration(
                            labelText: 'Cooldown (sec)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.snooze),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Notify Before Recovery'),
                    value: _notifyBeforeRecovery,
                    onChanged: (value) {
                      setState(() {
                        _notifyBeforeRecovery = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Alerting Section
                  _buildSectionTitle(context, 'Alerting Configuration'),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Enable Alerting'),
                    value: _alertingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _alertingEnabled = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _alertSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Alert Severity',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _alertSeverity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _alertChannelsController,
                    decoration: InputDecoration(
                      labelText: 'Alert Channels (comma-separated)',
                      prefixIcon: const Icon(Icons.notifications),
                      helperText: 'Example: email, slack, telegram',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags and Dependencies
                  _buildSectionTitle(context, 'Additional Info'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      prefixIcon: const Icon(Icons.label),
                      helperText: 'Example: production, critical, web',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _dependenciesController,
                    decoration: InputDecoration(
                      labelText: 'Dependencies (comma-separated service IDs)',
                      prefixIcon: const Icon(Icons.account_tree),
                      helperText: 'Example: mysql_001, redis_001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      CustomButton(
                        text: isEditing ? 'Update Service' : 'Create Service',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }
}
