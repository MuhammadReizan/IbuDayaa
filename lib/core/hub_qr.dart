/// The text printed in the Solar Hub's QR code. Members scan it to ask an admin
/// to verify they are using the hub now; the admin only approves or rejects.
///
/// One hub per cooperative today and the QR is fixed, so it lives here rather
/// than in settings. When several hubs exist, move it to a column on the hub.
const String kSolarHubQr = 'https://q.me-qr.com/6vovs0mu';

/// The hub works from 07.00 to 17.00. Booking for today after closing, and a QR
/// scan before opening or after closing, are refused with a message that says
/// which of the two it is (see `LocalSolarRepository`). Booking ahead for a
/// later day, or for later today before opening, is fine.
const int kHubOpensHour = 7;
const int kHubClosesHour = 17;

/// "07.00–17.00", for messages.
String get hubHoursLabel =>
    '${kHubOpensHour.toString().padLeft(2, "0")}.00–'
    '${kHubClosesHour.toString().padLeft(2, "0")}.00';

/// DEMO SWITCH — while true, a QR request outside the hub's hours is attached to
/// the nearest slot instead of being refused, so the flow can be shown at any
/// time of day. It is false: the hours are a real rule now. Only turn it on for
/// an exhibition demo that has to run in the evening.
const bool kQrIgnoresOperatingHours = false;

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
