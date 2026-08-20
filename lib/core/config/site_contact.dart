class SiteContact {
  static const company = 'NARAYANA MARINE';
  static const location = 'Phuket, Thailand';
  static const website = 'www.narayanamarine.com';
  static const primaryEmail = 'Narayamarine@gmail.com';
  static const secondaryEmail = 'Thunwisith@Gmail.com';
  static const phone = '+668-6885-6885';
  static const googleMapsUrl =
      'https://maps.app.goo.gl/iWNUuFDhxT3QmaaP8?g_st=iwb';
  static const address =
      '46/19 Moo 6, Ratsada, Mueang Phuket District, Phuket 83000, Thailand';
  static const instagramUrl =
      'https://www.instagram.com/phuket_narayana_marine?igsh=OWF2OGF4aWMzYWxh';
  static const facebookUrl =
      'https://www.facebook.com/share/1MNg9kzHL7/';
  static const telegramUrl =
      'https://t.me/phuket_narayana_marine';

  static Uri get whatsappUri => Uri.parse('https://wa.me/66868856885');
  static Uri get emailUri => Uri(scheme: 'mailto', path: primaryEmail);
  static Uri get secondaryEmailUri =>
      Uri(scheme: 'mailto', path: secondaryEmail);
  static Uri get instagramUri => Uri.parse(instagramUrl);
  static Uri get googleMapsUri => Uri.parse(googleMapsUrl);
  static Uri get facebookUri => Uri.parse(facebookUrl);
  static Uri get telegramUri => Uri.parse(telegramUrl);
}
