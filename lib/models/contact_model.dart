
enum ContactSource {
  registered,
  phoneContact,
}

class ContactModel {
  final String? uid;
  final String name;
  final String? phoneNumber;
  final String? email;
  final ContactSource source;
  final bool isOnline;

  const ContactModel({
    this.uid,
    required this.name,
    this.phoneNumber,
    this.email,
    required this.source,
    this.isOnline = false,
  });

  bool get isRegistered =>
      source == ContactSource.registered;
}

