import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../config/app_config.dart';
import '../../../../models/host.dart';
import '../../../dashboard/views/widgets/common/custom_button.dart';
import '../../../dashboard/views/widgets/common/custom_text_field.dart';
import '../../controllers/hosts_controller.dart';

class HostFormDialog extends StatefulWidget {
  final Host? host;

  const HostFormDialog({super.key, this.host});

  @override
  State<HostFormDialog> createState() => _HostFormDialogState();
}

class _HostFormDialogState extends State<HostFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hostIdController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _ipAddressController = TextEditingController();
  final _sshUserController = TextEditingController();
  final _sshPortController = TextEditingController(text: '22');
  final _sshKeyPathController = TextEditingController();
  final _sshPasswordController = TextEditingController();
  final _osController = TextEditingController();
  final _purposeController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedEnvironment;
  String? _selectedRegion;
  String? _selectedStatus = 'active';
  bool _useSudo = true;
  bool _obscurePassword = true;

  bool get isEditing => widget.host != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _hostIdController.text = widget.host!.hostId;
      _hostnameController.text = widget.host!.hostname;
      _ipAddressController.text = widget.host!.ipAddress;
      _selectedEnvironment = widget.host!.environment;
      _selectedRegion = widget.host!.region;
      _sshUserController.text = widget.host!.sshConfig.user;
      _sshPortController.text = widget.host!.sshConfig.port.toString();
      _sshKeyPathController.text = widget.host!.sshConfig.keyPath ?? '';
      _sshPasswordController.text = widget.host!.sshConfig.password ?? '';
      _useSudo = widget.host!.sshConfig.useSudo;
      _osController.text = widget.host!.metadata.os ?? '';
      _purposeController.text = widget.host!.metadata.purpose ?? '';
      _tagsController.text = widget.host!.metadata.tags.join(', ');
      _selectedStatus = widget.host!.status;
    }
  }

  @override
  void dispose() {
    _hostIdController.dispose();
    _hostnameController.dispose();
    _ipAddressController.dispose();
    _sshUserController.dispose();
    _sshPortController.dispose();
    _sshKeyPathController.dispose();
    _sshPasswordController.dispose();
    _osController.dispose();
    _purposeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<HostsController>();
    bool success;

    // Parse tags
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (isEditing) {
      success = await controller.updateHost(
        hostId: widget.host!.hostId,
        hostname: _hostnameController.text.trim(),
        ipAddress: _ipAddressController.text.trim(),
        environment: _selectedEnvironment,
        region: _selectedRegion,
        sshUser: _sshUserController.text.trim(),
        sshPort: int.tryParse(_sshPortController.text),
        sshKeyPath: _sshKeyPathController.text.trim().isEmpty
            ? null
            : _sshKeyPathController.text.trim(),
        sshPassword: _sshPasswordController.text.trim().isEmpty
            ? null
            : _sshPasswordController.text.trim(),
        useSudo: _useSudo,
        os: _osController.text.trim().isEmpty ? null : _osController.text.trim(),
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        status: _selectedStatus,
      );
    } else {
      success = await controller.createHost(
        hostname: _hostnameController.text.trim(),
        ipAddress: _ipAddressController.text.trim(),
        environment: _selectedEnvironment!,
        region: _selectedRegion!,
        sshUser: _sshUserController.text.trim(),
        sshPort: int.tryParse(_sshPortController.text) ?? 22,
        sshKeyPath: _sshKeyPathController.text.trim().isEmpty
            ? null
            : _sshKeyPathController.text.trim(),
        sshPassword: _sshPasswordController.text.trim().isEmpty
            ? null
            : _sshPasswordController.text.trim(),
        useSudo: _useSudo,
        os: _osController.text.trim().isEmpty ? null : _osController.text.trim(),
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        tags: tags,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HostsController>();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
                        isEditing ? 'Edit Host' : 'Add New Host',
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

                  // Host Basic Info Section
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Host ID and Hostname Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hostIdController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: isEditing ? 'Host ID' : 'Host ID (Auto-generated)',
                            prefixIcon: const Icon(Icons.fingerprint),
                            helperText: isEditing ? null : 'Generated from hostname',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _hostnameController,
                          decoration: InputDecoration(
                            labelText: 'Hostname *',
                            prefixIcon: const Icon(Icons.computer),
                            helperText: 'Example: web-server-01, db-main',
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Hostname is required';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // IP Address
                  CustomTextField(
                    controller: _ipAddressController,
                    label: 'IP Address *',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'IP Address is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Environment and Region Row
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: _selectedEnvironment,
                              decoration: const InputDecoration(
                                labelText: 'Environment *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.cloud_outlined),
                              ),
                              items: controller.availableEnvironments
                                  .map((env) => DropdownMenuItem(
                                        value: env,
                                        child: Text(env),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEnvironment = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Environment is required';
                                }
                                return null;
                              },
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: _selectedRegion,
                              decoration: const InputDecoration(
                                labelText: 'Region *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.public),
                              ),
                              items: controller.availableRegions
                                  .map((region) => DropdownMenuItem(
                                        value: region,
                                        child: Text(region),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Region is required';
                                }
                                return null;
                              },
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SSH Configuration Section
                  Text(
                    'SSH Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // SSH User and Port Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _sshUserController,
                          label: 'SSH User *',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'SSH User is required';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sshPortController,
                          decoration: const InputDecoration(
                            labelText: 'SSH Port *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Port is required';
                            }
                            final port = int.tryParse(value);
                            if (port == null || port < 1 || port > 65535) {
                              return 'Invalid port';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SSH Key Path
                  TextFormField(
                    controller: _sshKeyPathController,
                    decoration: InputDecoration(
                      labelText: 'SSH Key Path (optional)',
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                    validator: (value) {
                      // Either key path or password must be provided
                      if ((value == null || value.trim().isEmpty) &&
                          _sshPasswordController.text.trim().isEmpty) {
                        return 'Either SSH key path or password is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // SSH Password
                  TextFormField(
                    controller: _sshPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'SSH Password (optional)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: 'Use either SSH key or password for authentication',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      // Either key path or password must be provided
                      if ((value == null || value.trim().isEmpty) &&
                          _sshKeyPathController.text.trim().isEmpty) {
                        return 'Either SSH key path or password is required';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Use Sudo Checkbox
                  CheckboxListTile(
                    title: const Text('Use sudo for commands'),
                    value: _useSudo,
                    onChanged: (value) {
                      setState(() {
                        _useSudo = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Metadata Section
                  Text(
                    'Metadata (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // OS and Purpose Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _osController,
                          label: 'Operating System',
                          prefixIcon: Icons.laptop_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _purposeController,
                          label: 'Purpose',
                          prefixIcon: Icons.assignment_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      prefixIcon: const Icon(Icons.label_outline),
                      helperText: 'Example: web, nginx, production',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Status (only for editing)
                  if (isEditing)
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(
                            value: 'maintenance', child: Text('Maintenance')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
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
                        text: isEditing ? 'Update Host' : 'Create Host',
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
}
