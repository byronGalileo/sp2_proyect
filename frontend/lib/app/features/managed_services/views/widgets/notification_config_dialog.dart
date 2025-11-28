import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../../../../config/themes/app_theme.dart';
import '../../../../models/managed_service.dart';
import '../../../../models/notification_config.dart';
import '../../controllers/notification_config_controller.dart';

class NotificationConfigDialog extends StatefulWidget {
  final ManagedService service;

  const NotificationConfigDialog({super.key, required this.service});

  @override
  State<NotificationConfigDialog> createState() =>
      _NotificationConfigDialogState();
}

class _NotificationConfigDialogState extends State<NotificationConfigDialog> {
  late final NotificationConfigController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationConfigController());
    controller.loadConfig(widget.service.serviceId, widget.service.hostId);
  }

  @override
  void dispose() {
    Get.delete<NotificationConfigController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.primaryDark,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notification Configuration',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${widget.service.displayName ?? widget.service.serviceName} | Host: ${widget.service.hostId}',
              style: const TextStyle(color: AppColors.textLight),
            ),
            const Divider(color: AppColors.border, height: 32),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.config.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Text(
                      'Error: ${controller.errorMessage.value}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                if (controller.config.value == null) {
                  return _buildCreateConfigView();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      // Mobile/Tablet layout (Vertical)
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSettingsSection(),
                            const Divider(height: 32, color: AppColors.border),
                            _buildContactsSection(isMobile: true),
                          ],
                        ),
                      );
                    } else {
                      // Desktop layout (Horizontal)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(child: _buildSettingsSection()),
                          ),
                          const VerticalDivider(width: 32, color: AppColors.border),
                          Expanded(
                            flex: 3,
                            child: _buildContactsSection(),
                          ),
                        ],
                      );
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateConfigView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(EvaIcons.bellOutline,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'No notification configuration found',
            style: TextStyle(color: AppColors.textOnPrimary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a configuration to start receiving alerts.',
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          _buildSettingsForm(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.createConfig(
                widget.service.serviceId, widget.service.hostId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration Settings',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsForm(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => controller.updateSettings(
              widget.service.serviceId, widget.service.hostId),
          child: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildSettingsForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: controller.selectedProvider.value,
          decoration: const InputDecoration(
            labelText: 'SMS Provider',
            labelStyle: TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(),
            prefixIcon: Icon(EvaIcons.messageSquareOutline, color: AppColors.textLight),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textLight),
            ),
          ),
          dropdownColor: AppColors.primaryDark,
          style: const TextStyle(color: AppColors.textOnPrimary),
          items: const [
            DropdownMenuItem(value: 'twilio', child: Text('Twilio')),
            DropdownMenuItem(value: 'aws_sns', child: Text('AWS SNS')),
          ],
          onChanged: (value) => controller.selectedProvider.value = value!,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: controller.cooldownMinutes.value.toString(),
          decoration: const InputDecoration(
            labelText: 'Cooldown (minutes)',
            labelStyle: TextStyle(color: AppColors.textLight),
            border: OutlineInputBorder(),
            prefixIcon: Icon(EvaIcons.clockOutline, color: AppColors.textLight),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.textLight),
            ),
          ),
          style: const TextStyle(color: AppColors.textOnPrimary),
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              controller.cooldownMinutes.value = int.tryParse(value) ?? 5,
        ),
      ],
    );
  }

  Widget _buildContactsSection({bool isMobile = false}) {
    final contacts = controller.config.value?.contacts ?? [];
    
    Widget content = contacts.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No contacts added yet',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: isMobile,
            physics: isMobile ? const NeverScrollableScrollPhysics() : null,
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                color: AppColors.primaryBase,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: contact.enabled
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.textSecondary.withOpacity(0.2),
                    child: Icon(
                      EvaIcons.personOutline,
                      color: contact.enabled
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(color: AppColors.textOnPrimary),
                  ),
                  subtitle: Text(
                    '${contact.phone} • ${contact.email} • ${contact.channels.join(", ")}',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.textLight),
                        onPressed: () => _showContactDialog(contact: contact),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => controller.deleteContact(
                            widget.service.serviceId,
                            widget.service.hostId,
                            contact.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

    if (!isMobile) {
      content = Expanded(child: content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Contacts',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showContactDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Contact'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  void _showContactDialog({Contact? contact}) {
    final nameController = TextEditingController(text: contact?.name);
    final phoneController = TextEditingController(text: contact?.phone);
    final emailController = TextEditingController(text: contact?.email);
    final enabled = (contact?.enabled ?? true).obs;
    final channels = (contact?.channels ?? ['sms']).obs;
    final notifyOn = (contact?.notifyOn ??
            ['service_down', 'service_restart_failed'])
        .obs;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          contact == null ? 'Add Contact' : 'Edit Contact',
          style: const TextStyle(color: AppColors.textOnPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textLight),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                ),
                style: const TextStyle(color: AppColors.textOnPrimary),
                enabled: contact == null, // Name is ID, cannot change
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: AppColors.textLight),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  hintText: '+502...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textOnPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppColors.textLight),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  hintText: 'example@email.com',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: const TextStyle(color: AppColors.textOnPrimary),
              ),
              const SizedBox(height: 16),
              Obx(() => SwitchListTile(
                    title: const Text('Enabled',
                        style: TextStyle(color: AppColors.textOnPrimary)),
                    value: enabled.value,
                    onChanged: (val) => enabled.value = val,
                    activeColor: AppColors.accentOrange,
                    activeTrackColor: AppColors.accentOrange.withOpacity(0.5),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.textSecondary.withOpacity(0.5),
                  )),
              const SizedBox(height: 16),
              const Text('Channels',
                  style: TextStyle(color: AppColors.textOnPrimary)),
              Obx(() => Wrap(
                    spacing: 8,
                    children: ['sms', 'email', 'slack'].map((channel) {
                      return FilterChip(
                        label: Text(channel),
                        selected: channels.contains(channel),
                        onSelected: (selected) {
                          if (selected) {
                            channels.add(channel);
                          } else {
                            channels.remove(channel);
                          }
                        },
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 16),
              const Text('Notify On',
                  style: TextStyle(color: AppColors.textOnPrimary)),
              Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      'service_down',
                      'service_restart_failed',
                      'service_recovered'
                    ].map((event) {
                      return FilterChip(
                        label: Text(event),
                        selected: notifyOn.contains(event),
                        onSelected: (selected) {
                          if (selected) {
                            notifyOn.add(event);
                          } else {
                            notifyOn.remove(event);
                          }
                        },
                      );
                    }).toList(),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(foregroundColor: AppColors.textLight),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContact = Contact(
                name: nameController.text,
                phone: phoneController.text,
                email: emailController.text,
                enabled: enabled.value,
                channels: channels,
                notifyOn: notifyOn,
              );
              if (contact == null) {
                controller.addContact(widget.service.serviceId,
                    widget.service.hostId, newContact);
              } else {
                controller.updateContact(widget.service.serviceId,
                    widget.service.hostId, contact.name, newContact);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
