class ApiUrls {
  static const authLogin = '/auth/login';
  static const authProfile = '/auth/profile';
  static const authSignup = '/auth/sign-up';
  static const refreshToken = '/auth/refresh-token';

  static const linkProvider = '/users/link-provider';
  static const updateProfile = '/users/update-profile';

  static const notificationSettings = '/notification-settings';
  static const notificationSettingsUpdate = '/notification-settings/update';

  static const privacySettings = '/privacy-settings';
  static const privacySettingsUpdate = '/privacy-settings/update';

  static const dataUsageSettings = '/data-usage-settings';
  static const dataUsageSettingsUpdate = '/data-usage-settings/update';

  static const contacts = '/contacts';
  static const contactsAddByPhone = '/contacts/add-by-phone';
  static const contactsMatchPhonebook = '/contacts/match-phonebook';
  static const contactsMyQr = '/contacts/me/qr';
  static const contactsAddByQr = '/contacts/add-by-qr';
  static const contactsBase = '/contacts';
  static const contactsAcceptRequest = '/contacts'; // + '/:id/accept'
  static const contactsRejectRequest = '/contacts'; // + '/:id/reject'
  static const contactsCancelRequest = '/contacts'; // + '/:id/cancel'

  static const conversations = '/conversations';
}
