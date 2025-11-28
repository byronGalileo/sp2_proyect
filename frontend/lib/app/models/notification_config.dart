class NotificationConfig {
  final String serviceName;
  final String host;
  final String smsProvider;
  final int cooldownMinutes;
  final List<Contact> contacts;

  NotificationConfig({
    required this.serviceName,
    required this.host,
    required this.smsProvider,
    required this.cooldownMinutes,
    required this.contacts,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      serviceName: json['service_name'] ?? '',
      host: json['host'] ?? '',
      smsProvider: json['sms_provider'] ?? 'aws_sns',
      cooldownMinutes: json['cooldown_minutes'] ?? 5,
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => Contact.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'host': host,
      'sms_provider': smsProvider,
      'cooldown_minutes': cooldownMinutes,
      'contacts': contacts.map((e) => e.toJson()).toList(),
    };
  }
}

class Contact {
  final String name;
  final String phone;
  final String email;
  final bool enabled;
  final List<String> channels;
  final List<String> notifyOn;

  Contact({
    required this.name,
    required this.phone,
    this.email = '',
    required this.enabled,
    required this.channels,
    required this.notifyOn,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      enabled: json['enabled'] ?? true,
      channels: List<String>.from(json['channels'] ?? []),
      notifyOn: List<String>.from(json['notify_on'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'enabled': enabled,
      'channels': channels,
      'notify_on': notifyOn,
    };
  }
}
