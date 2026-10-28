/// Initial first-level subunits for the clinical-year Library.
///
/// These are taxonomy labels only, not medical learning content.
/// Add future subunits here without changing the Library UI.
class InitialTaxonomySubunit {
  const InitialTaxonomySubunit({
    required this.uuid,
    required this.parentSlug,
    required this.title,
    required this.slug,
    required this.sortOrder,
  });

  final String uuid;
  final String parentSlug;
  final String title;
  final String slug;
  final int sortOrder;
}

const initialTaxonomySubunits = <InitialTaxonomySubunit>[
  // Medicine
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000101',
      parentSlug: 'medicine',
      title: 'Cardiology',
      slug: 'cardiology',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000102',
      parentSlug: 'medicine',
      title: 'Respiratory Medicine',
      slug: 'respiratory-medicine',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000103',
      parentSlug: 'medicine',
      title: 'Gastroenterology and Hepatology',
      slug: 'gastroenterology-and-hepatology',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000104',
      parentSlug: 'medicine',
      title: 'Nephrology',
      slug: 'nephrology',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000105',
      parentSlug: 'medicine',
      title: 'Neurology',
      slug: 'neurology',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000106',
      parentSlug: 'medicine',
      title: 'Endocrinology and Metabolism',
      slug: 'endocrinology-and-metabolism',
      sortOrder: 5),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000107',
      parentSlug: 'medicine',
      title: 'Haematology and Oncology',
      slug: 'haematology-and-oncology',
      sortOrder: 6),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000108',
      parentSlug: 'medicine',
      title: 'Rheumatology',
      slug: 'rheumatology',
      sortOrder: 7),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000109',
      parentSlug: 'medicine',
      title: 'Infectious Diseases',
      slug: 'infectious-diseases',
      sortOrder: 8),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000110',
      parentSlug: 'medicine',
      title: 'Dermatology',
      slug: 'dermatology',
      sortOrder: 9),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000111',
      parentSlug: 'medicine',
      title: 'Clinical Immunology and Allergy',
      slug: 'clinical-immunology-and-allergy',
      sortOrder: 10),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000112',
      parentSlug: 'medicine',
      title: 'Geriatric Medicine',
      slug: 'geriatric-medicine',
      sortOrder: 11),

  // Surgery
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000201',
      parentSlug: 'surgery',
      title: 'General Surgery',
      slug: 'general-surgery',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000202',
      parentSlug: 'surgery',
      title: 'Orthopaedics and Trauma',
      slug: 'orthopaedics-and-trauma',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000203',
      parentSlug: 'surgery',
      title: 'Neurosurgery',
      slug: 'neurosurgery',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000204',
      parentSlug: 'surgery',
      title: 'Urology',
      slug: 'urology',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000205',
      parentSlug: 'surgery',
      title: 'Plastic and Reconstructive Surgery',
      slug: 'plastic-and-reconstructive-surgery',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000206',
      parentSlug: 'surgery',
      title: 'Paediatric Surgery',
      slug: 'paediatric-surgery',
      sortOrder: 5),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000207',
      parentSlug: 'surgery',
      title: 'Cardiothoracic Surgery',
      slug: 'cardiothoracic-surgery',
      sortOrder: 6),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000208',
      parentSlug: 'surgery',
      title: 'Vascular Surgery',
      slug: 'vascular-surgery',
      sortOrder: 7),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000209',
      parentSlug: 'surgery',
      title: 'Surgical Oncology',
      slug: 'surgical-oncology',
      sortOrder: 8),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000210',
      parentSlug: 'surgery',
      title: 'Ear, Nose and Throat Surgery',
      slug: 'ear-nose-and-throat-surgery',
      sortOrder: 9),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000211',
      parentSlug: 'surgery',
      title: 'Ophthalmology',
      slug: 'ophthalmology',
      sortOrder: 10),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000212',
      parentSlug: 'surgery',
      title: 'Anaesthesia and Perioperative Care',
      slug: 'anaesthesia-and-perioperative-care',
      sortOrder: 11),

  // Obstetrics and Gynaecology
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000301',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Obstetrics',
      slug: 'obstetrics',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000302',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Gynaecology',
      slug: 'gynaecology',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000303',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Maternal-Fetal Medicine',
      slug: 'maternal-fetal-medicine',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000304',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Reproductive Medicine and Infertility',
      slug: 'reproductive-medicine-and-infertility',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000305',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Gynaecological Oncology',
      slug: 'gynaecological-oncology',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000306',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Urogynaecology and Pelvic Floor',
      slug: 'urogynaecology-and-pelvic-floor',
      sortOrder: 5),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000307',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Family Planning and Contraception',
      slug: 'family-planning-and-contraception',
      sortOrder: 6),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000308',
      parentSlug: 'obstetrics-and-gynaecology',
      title: 'Reproductive and Sexual Health',
      slug: 'reproductive-and-sexual-health',
      sortOrder: 7),

  // Paediatrics and Child Health
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000401',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Neonatology',
      slug: 'neonatology',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000402',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Cardiology',
      slug: 'paediatric-cardiology',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000403',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Respiratory Medicine',
      slug: 'paediatric-respiratory-medicine',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000404',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Gastroenterology and Nutrition',
      slug: 'paediatric-gastroenterology-and-nutrition',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000405',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Nephrology',
      slug: 'paediatric-nephrology',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000406',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Neurology and Development',
      slug: 'paediatric-neurology-and-development',
      sortOrder: 5),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000407',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Endocrinology',
      slug: 'paediatric-endocrinology',
      sortOrder: 6),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000408',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Haematology and Oncology',
      slug: 'paediatric-haematology-and-oncology',
      sortOrder: 7),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000409',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Infectious Diseases',
      slug: 'paediatric-infectious-diseases',
      sortOrder: 8),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000410',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Rheumatology and Immunology',
      slug: 'paediatric-rheumatology-and-immunology',
      sortOrder: 9),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000411',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Adolescent Health',
      slug: 'adolescent-health',
      sortOrder: 10),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000412',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Paediatric Emergency and Critical Care',
      slug: 'paediatric-emergency-and-critical-care',
      sortOrder: 11),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000413',
      parentSlug: 'paediatrics-and-child-health',
      title: 'Child Health and Development',
      slug: 'child-health-and-development',
      sortOrder: 12),

  // Community Health
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000501',
      parentSlug: 'community-health',
      title: 'Epidemiology and Biostatistics',
      slug: 'epidemiology-and-biostatistics',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000502',
      parentSlug: 'community-health',
      title: 'Primary Health Care',
      slug: 'primary-health-care',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000503',
      parentSlug: 'community-health',
      title: 'Maternal, Newborn and Child Health',
      slug: 'maternal-newborn-and-child-health',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000504',
      parentSlug: 'community-health',
      title: 'Communicable Diseases',
      slug: 'communicable-diseases',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000505',
      parentSlug: 'community-health',
      title: 'Non-Communicable Diseases',
      slug: 'non-communicable-diseases',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000506',
      parentSlug: 'community-health',
      title: 'Environmental and Occupational Health',
      slug: 'environmental-and-occupational-health',
      sortOrder: 5),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000507',
      parentSlug: 'community-health',
      title: 'Health Systems, Policy and Management',
      slug: 'health-systems-policy-and-management',
      sortOrder: 6),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000508',
      parentSlug: 'community-health',
      title: 'Health Promotion and Education',
      slug: 'health-promotion-and-education',
      sortOrder: 7),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000509',
      parentSlug: 'community-health',
      title: 'Nutrition and Public Health',
      slug: 'nutrition-and-public-health',
      sortOrder: 8),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000510',
      parentSlug: 'community-health',
      title: 'Research Methods and Global Health',
      slug: 'research-methods-and-global-health',
      sortOrder: 9),

  // Dental
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000601',
      parentSlug: 'dental',
      title: 'Periodontology',
      slug: 'periodontology',
      sortOrder: 0),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000602',
      parentSlug: 'dental',
      title: 'Oral Pathology',
      slug: 'oral-pathology',
      sortOrder: 1),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000603',
      parentSlug: 'dental',
      title: 'Oral and Maxillofacial Radiology',
      slug: 'oral-and-maxillofacial-radiology',
      sortOrder: 2),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000604',
      parentSlug: 'dental',
      title: 'Paediatric Dentistry',
      slug: 'paediatric-dentistry',
      sortOrder: 3),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000605',
      parentSlug: 'dental',
      title: 'Orthodontics',
      slug: 'orthodontics',
      sortOrder: 4),
  InitialTaxonomySubunit(
      uuid: '10000000-0000-5000-8000-000000000606',
      parentSlug: 'dental',
      title: 'Conservative Dentistry',
      slug: 'conservative-dentistry',
      sortOrder: 5),
];
