/// A made-up person for the demo data.
class DemoPilot {
  const DemoPilot(this.firstName, this.lastName, this.club, this.city);

  final String firstName;
  final String lastName;
  final String club;
  final String city;

  /// The demo roster; a pilot's number in the list is its profile number.
  static const List<DemoPilot> roster = [
    DemoPilot('Avery', 'Brooks', 'Front Range Soaring', 'Longmont'),
    DemoPilot('Blake', 'Castillo', 'Front Range Soaring', 'Boulder'),
    DemoPilot('Casey', 'Dunn', 'High Plains RC', 'Fort Collins'),
    DemoPilot('Devon', 'Ellis', 'High Plains RC', 'Greeley'),
    DemoPilot('Emery', 'Foster', 'Mile High Flyers', 'Denver'),
    DemoPilot('Finley', 'Garcia', 'Mile High Flyers', 'Aurora'),
    DemoPilot('Harper', 'Hughes', 'Rocky Mountain Sailplanes', 'Golden'),
    DemoPilot('Indigo', 'Ito', 'Rocky Mountain Sailplanes', 'Arvada'),
    DemoPilot('Jordan', 'Kim', 'Front Range Soaring', 'Louisville'),
    DemoPilot('Kai', 'Larsen', 'High Plains RC', 'Loveland'),
    DemoPilot('Logan', 'Moreno', 'Mile High Flyers', 'Littleton'),
    DemoPilot('Morgan', 'Nguyen', 'Rocky Mountain Sailplanes', 'Lakewood'),
    DemoPilot('Noel', 'Ortiz', 'Front Range Soaring', 'Erie'),
    DemoPilot('Oakley', 'Patel', 'High Plains RC', 'Windsor'),
    DemoPilot('Parker', 'Quinn', 'Mile High Flyers', 'Centennial'),
    DemoPilot('Quinn', 'Reyes', 'Rocky Mountain Sailplanes', 'Westminster'),
    DemoPilot('Riley', 'Sato', 'Front Range Soaring', 'Lafayette'),
    DemoPilot('Sage', 'Tran', 'High Plains RC', 'Berthoud'),
  ];
}
