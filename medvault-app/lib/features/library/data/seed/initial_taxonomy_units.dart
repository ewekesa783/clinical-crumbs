/// Initial top-level units in the MedVault Library.
///
/// This list is deliberately extensible: add future units here rather than
/// hard-coding the root list into the Library UI. Existing records are never
/// overwritten by the initial seeder.
class InitialTaxonomyUnit {
  const InitialTaxonomyUnit({
    required this.uuid,
    required this.title,
    required this.slug,
    required this.sortOrder,
  });

  final String uuid;
  final String title;
  final String slug;
  final int sortOrder;
}

const initialTaxonomyUnits = <InitialTaxonomyUnit>[
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000001',
    title: 'Medicine',
    slug: 'medicine',
    sortOrder: 0,
  ),
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000002',
    title: 'Surgery',
    slug: 'surgery',
    sortOrder: 1,
  ),
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000003',
    title: 'Obstetrics and Gynaecology',
    slug: 'obstetrics-and-gynaecology',
    sortOrder: 2,
  ),
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000004',
    title: 'Paediatrics and Child Health',
    slug: 'paediatrics-and-child-health',
    sortOrder: 3,
  ),
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000005',
    title: 'Community Health',
    slug: 'community-health',
    sortOrder: 4,
  ),
  InitialTaxonomyUnit(
    uuid: '10000000-0000-5000-8000-000000000006',
    title: 'Dental',
    slug: 'dental',
    sortOrder: 5,
  ),
];
