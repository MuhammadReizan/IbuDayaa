/// The text printed in the Solar Hub's QR code. Members scan it to ask an admin
/// to verify they are using the hub now; the admin only approves or rejects.
///
/// One hub per cooperative today and the QR is fixed, so it lives here rather
/// than in settings. When several hubs exist, move it to a column on the hub.
const String kSolarHubQr = 'https://q.me-qr.com/6vovs0mu';

/// DEMO SWITCH — while true, a QR request outside the hub's opening hours is
/// attached to the nearest slot instead of being refused, so the flow can be
/// shown at any time of day. Set to false before a real pilot: the hub's
/// operating hours are a real rule (capacity is defined per slot).
const bool kQrIgnoresOperatingHours = false;
