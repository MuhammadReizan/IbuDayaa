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
const bool kQrIgnoresOperatingHours = true;

/// DEMO SWITCH — while true, a QR request is never refused for lack of energy
/// (slot capacity, the member's quota), simultaneous load or a slot the admin
/// closed: the admin still
/// decides whether to approve it. Those limits are real for bookings made from
/// the booking screen; this only relaxes the scan so an exhibition demo cannot
/// dead-end on "sisa kWh tidak cukup". Set to false before a real pilot.
const bool kQrIgnoresHubLimits = true;

/// While true, a member must have booked a slot for today before the scan
/// counts: the scan is her arrival at that booking. Without one the scan is
/// refused with a prompt to book first. Bookings for today can only be made
/// for slots that have not ended, so outside opening hours there is nothing to
/// scan against — set to false to let a scan open a request on its own.
const bool kQrRequiresBooking = true;
