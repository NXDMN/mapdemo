enum NearbyPlaces {
  hdbBranches(
    name: "HDB Branches",
    icon: "https://www.onemap.gov.sg/images/theme/hdb_branches.jpg",
  ),
  communityClubs(
    name: "Community Clubs",
    icon: "https://www.onemap.gov.sg/images/theme/paheadquarters.png",
  ),
  libraries(
    name: "Libraries",
    icon: "https://www.onemap.gov.sg/images/theme/libraries.png",
  );

  const NearbyPlaces({
    required this.name,
    required this.icon,
  });

  final String name;
  final String icon;
}
