/// Initial third-level Library taxonomy labels.
///
/// These are organisational labels only, not medical learning content.
/// Each topic belongs to an existing specialty identified by its slug.
class InitialTaxonomyTopic {
  const InitialTaxonomyTopic({
    required this.uuid,
    required this.parentUuid,
    required this.title,
    required this.slug,
    required this.sortOrder,
  });

  final String uuid;
  final String parentUuid;
  final String title;
  final String slug;
  final int sortOrder;
}

const initialTaxonomyTopics = <InitialTaxonomyTopic>[
  // Medicine > Neurology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001001',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Approach to Neurological Symptoms and Signs',
    slug: 'approach-to-neurological-symptoms-and-signs',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001002',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Headache and Facial Pain',
    slug: 'headache-and-facial-pain',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001003',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Seizures and Epilepsy',
    slug: 'seizures-and-epilepsy',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001004',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Cerebrovascular Disease',
    slug: 'cerebrovascular-disease',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001005',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Movement Disorders',
    slug: 'movement-disorders',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001006',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Myopathies',
    slug: 'myopathies',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001007',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Neuromuscular Junction Disorders',
    slug: 'neuromuscular-junction-disorders',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001008',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Peripheral Neuropathies',
    slug: 'peripheral-neuropathies',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001009',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Motor Neuron Diseases',
    slug: 'motor-neuron-diseases',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001010',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Demyelinating Disorders',
    slug: 'demyelinating-disorders',
    sortOrder: 9,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001011',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Central Nervous System Infections',
    slug: 'central-nervous-system-infections',
    sortOrder: 10,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001012',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Spinal Cord Disorders',
    slug: 'spinal-cord-disorders',
    sortOrder: 11,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001013',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Cranial Nerve Disorders',
    slug: 'cranial-nerve-disorders',
    sortOrder: 12,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001014',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Disorders of Consciousness',
    slug: 'disorders-of-consciousness',
    sortOrder: 13,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001015',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Neurodegenerative Disorders',
    slug: 'neurodegenerative-disorders',
    sortOrder: 14,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001016',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Neurocutaneous Syndromes',
    slug: 'neurocutaneous-syndromes',
    sortOrder: 15,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001017',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Sleep Disorders',
    slug: 'sleep-disorders',
    sortOrder: 16,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001018',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Autonomic Nervous System Disorders',
    slug: 'autonomic-nervous-system-disorders',
    sortOrder: 17,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001019',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Gait and Balance Disorders',
    slug: 'gait-and-balance-disorders',
    sortOrder: 18,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001020',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Neurogenetic Disorders',
    slug: 'neurogenetic-disorders',
    sortOrder: 19,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000001021',
    parentUuid: '10000000-0000-5000-8000-000000000105',
    title: 'Neurodiagnostic Investigations',
    slug: 'neurodiagnostic-investigations',
    sortOrder: 20,
  ),

  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002001',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Approach to Cardiovascular Symptoms and Signs',
    slug: 'approach-to-cardiovascular-symptoms-and-signs',
    sortOrder: 0,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002002',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Hypertension',
    slug: 'hypertension',
    sortOrder: 1,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002003',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Ischaemic Heart Disease',
    slug: 'ischaemic-heart-disease',
    sortOrder: 2,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002004',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Heart Failure',
    slug: 'heart-failure',
    sortOrder: 3,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002005',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Valvular Heart Disease',
    slug: 'valvular-heart-disease',
    sortOrder: 4,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002006',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Cardiomyopathies',
    slug: 'cardiomyopathies',
    sortOrder: 5,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002007',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Cardiac Arrhythmias',
    slug: 'cardiac-arrhythmias',
    sortOrder: 6,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002008',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Pericardial Diseases',
    slug: 'pericardial-diseases',
    sortOrder: 7,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002009',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Congenital Heart Disease',
    slug: 'congenital-heart-disease',
    sortOrder: 8,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002010',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Peripheral Vascular Disease',
    slug: 'peripheral-vascular-disease',
    sortOrder: 9,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002011',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Pulmonary Hypertension',
    slug: 'pulmonary-hypertension',
    sortOrder: 10,
  ),
  // Medicine > Cardiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002012',
    parentUuid: '10000000-0000-5000-8000-000000000101',
    title: 'Cardiovascular Emergencies',
    slug: 'cardiovascular-emergencies',
    sortOrder: 11,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002013',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Approach to Respiratory Symptoms and Signs',
    slug: 'approach-to-respiratory-symptoms-and-signs',
    sortOrder: 0,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002014',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Asthma',
    slug: 'asthma',
    sortOrder: 1,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002015',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Chronic Obstructive Pulmonary Disease',
    slug: 'chronic-obstructive-pulmonary-disease',
    sortOrder: 2,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002016',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Pneumonia',
    slug: 'pneumonia',
    sortOrder: 3,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002017',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Tuberculosis',
    slug: 'tuberculosis',
    sortOrder: 4,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002018',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Bronchiectasis',
    slug: 'bronchiectasis',
    sortOrder: 5,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002019',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Interstitial Lung Diseases',
    slug: 'interstitial-lung-diseases',
    sortOrder: 6,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002020',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Pleural Diseases',
    slug: 'pleural-diseases',
    sortOrder: 7,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002021',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Pulmonary Vascular Diseases',
    slug: 'pulmonary-vascular-diseases',
    sortOrder: 8,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002022',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Lung Cancer',
    slug: 'lung-cancer',
    sortOrder: 9,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002023',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Sleep-Related Breathing Disorders',
    slug: 'sleep-related-breathing-disorders',
    sortOrder: 10,
  ),
  // Medicine > Respiratory Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002024',
    parentUuid: '10000000-0000-5000-8000-000000000102',
    title: 'Respiratory Failure',
    slug: 'respiratory-failure',
    sortOrder: 11,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002025',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Approach to Gastrointestinal Symptoms and Signs',
    slug: 'approach-to-gastrointestinal-symptoms-and-signs',
    sortOrder: 0,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002026',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Oesophageal Disorders',
    slug: 'oesophageal-disorders',
    sortOrder: 1,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002027',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Peptic Ulcer Disease and Dyspepsia',
    slug: 'peptic-ulcer-disease-and-dyspepsia',
    sortOrder: 2,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002028',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Inflammatory Bowel Disease',
    slug: 'inflammatory-bowel-disease',
    sortOrder: 3,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002029',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Malabsorption and Coeliac Disease',
    slug: 'malabsorption-and-coeliac-disease',
    sortOrder: 4,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002030',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Acute and Chronic Pancreatitis',
    slug: 'acute-and-chronic-pancreatitis',
    sortOrder: 5,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002031',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Gallbladder and Biliary Tract Diseases',
    slug: 'gallbladder-and-biliary-tract-diseases',
    sortOrder: 6,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002032',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Viral Hepatitis',
    slug: 'viral-hepatitis',
    sortOrder: 7,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002033',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Chronic Liver Disease and Cirrhosis',
    slug: 'chronic-liver-disease-and-cirrhosis',
    sortOrder: 8,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002034',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Portal Hypertension',
    slug: 'portal-hypertension',
    sortOrder: 9,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002035',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Gastrointestinal Bleeding',
    slug: 'gastrointestinal-bleeding',
    sortOrder: 10,
  ),
  // Medicine > Gastroenterology and Hepatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002036',
    parentUuid: '10000000-0000-5000-8000-000000000103',
    title: 'Gastrointestinal Malignancies',
    slug: 'gastrointestinal-malignancies',
    sortOrder: 11,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002037',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Approach to Renal and Urinary Symptoms',
    slug: 'approach-to-renal-and-urinary-symptoms',
    sortOrder: 0,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002038',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Acute Kidney Injury',
    slug: 'acute-kidney-injury',
    sortOrder: 1,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002039',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Chronic Kidney Disease',
    slug: 'chronic-kidney-disease',
    sortOrder: 2,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002040',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Glomerular Diseases',
    slug: 'glomerular-diseases',
    sortOrder: 3,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002041',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Nephrotic Syndrome',
    slug: 'nephrotic-syndrome',
    sortOrder: 4,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002042',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Tubulointerstitial Diseases',
    slug: 'tubulointerstitial-diseases',
    sortOrder: 5,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002043',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Electrolyte Disorders',
    slug: 'electrolyte-disorders',
    sortOrder: 6,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002044',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Acid–Base Disorders',
    slug: 'acid-base-disorders',
    sortOrder: 7,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002045',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Fluid Balance Disorders',
    slug: 'fluid-balance-disorders',
    sortOrder: 8,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002046',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Hypertension and Kidney Disease',
    slug: 'hypertension-and-kidney-disease',
    sortOrder: 9,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002047',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Dialysis and Renal Replacement Therapy',
    slug: 'dialysis-and-renal-replacement-therapy',
    sortOrder: 10,
  ),
  // Medicine > Nephrology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002048',
    parentUuid: '10000000-0000-5000-8000-000000000104',
    title: 'Kidney Transplantation',
    slug: 'kidney-transplantation',
    sortOrder: 11,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002049',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Diabetes Mellitus',
    slug: 'diabetes-mellitus',
    sortOrder: 0,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002050',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Acute Diabetic Emergencies',
    slug: 'acute-diabetic-emergencies',
    sortOrder: 1,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002051',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Thyroid Disorders',
    slug: 'thyroid-disorders',
    sortOrder: 2,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002052',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Adrenal Disorders',
    slug: 'adrenal-disorders',
    sortOrder: 3,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002053',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Pituitary and Hypothalamic Disorders',
    slug: 'pituitary-and-hypothalamic-disorders',
    sortOrder: 4,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002054',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Parathyroid and Calcium Disorders',
    slug: 'parathyroid-and-calcium-disorders',
    sortOrder: 5,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002055',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Metabolic Bone Disease',
    slug: 'metabolic-bone-disease',
    sortOrder: 6,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002056',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Obesity and Metabolic Syndrome',
    slug: 'obesity-and-metabolic-syndrome',
    sortOrder: 7,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002057',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Lipid Disorders',
    slug: 'lipid-disorders',
    sortOrder: 8,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002058',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Disorders of Sexual Development and Gonadal Function',
    slug: 'disorders-of-sexual-development-and-gonadal-function',
    sortOrder: 9,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002059',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Endocrine Tumours',
    slug: 'endocrine-tumours',
    sortOrder: 10,
  ),
  // Medicine > Endocrinology and Metabolism
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002060',
    parentUuid: '10000000-0000-5000-8000-000000000106',
    title: 'Inherited Metabolic Disorders',
    slug: 'inherited-metabolic-disorders',
    sortOrder: 11,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002061',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Approach to Haematological Abnormalities',
    slug: 'approach-to-haematological-abnormalities',
    sortOrder: 0,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002062',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Anaemias',
    slug: 'anaemias',
    sortOrder: 1,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002063',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Haemolytic Disorders',
    slug: 'haemolytic-disorders',
    sortOrder: 2,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002064',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Haemoglobinopathies',
    slug: 'haemoglobinopathies',
    sortOrder: 3,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002065',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Bleeding and Coagulation Disorders',
    slug: 'bleeding-and-coagulation-disorders',
    sortOrder: 4,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002066',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Thrombosis and Thrombophilia',
    slug: 'thrombosis-and-thrombophilia',
    sortOrder: 5,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002067',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Platelet Disorders',
    slug: 'platelet-disorders',
    sortOrder: 6,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002068',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'White Cell Disorders',
    slug: 'white-cell-disorders',
    sortOrder: 7,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002069',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Leukaemias',
    slug: 'leukaemias',
    sortOrder: 8,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002070',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Lymphomas',
    slug: 'lymphomas',
    sortOrder: 9,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002071',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Plasma Cell Disorders',
    slug: 'plasma-cell-disorders',
    sortOrder: 10,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002072',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Solid Tumours',
    slug: 'solid-tumours',
    sortOrder: 11,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002073',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Transfusion Medicine',
    slug: 'transfusion-medicine',
    sortOrder: 12,
  ),
  // Medicine > Haematology and Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002074',
    parentUuid: '10000000-0000-5000-8000-000000000107',
    title: 'Haematological and Oncological Emergencies',
    slug: 'haematological-and-oncological-emergencies',
    sortOrder: 13,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002075',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Approach to Musculoskeletal Symptoms',
    slug: 'approach-to-musculoskeletal-symptoms',
    sortOrder: 0,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002076',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Rheumatoid Arthritis',
    slug: 'rheumatoid-arthritis',
    sortOrder: 1,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002077',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Systemic Lupus Erythematosus',
    slug: 'systemic-lupus-erythematosus',
    sortOrder: 2,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002078',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Spondyloarthritis',
    slug: 'spondyloarthritis',
    sortOrder: 3,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002079',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Crystal Arthropathies',
    slug: 'crystal-arthropathies',
    sortOrder: 4,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002080',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Osteoarthritis',
    slug: 'osteoarthritis',
    sortOrder: 5,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002081',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Systemic Sclerosis',
    slug: 'systemic-sclerosis',
    sortOrder: 6,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002082',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Inflammatory Myopathies',
    slug: 'inflammatory-myopathies',
    sortOrder: 7,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002083',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Vasculitis',
    slug: 'vasculitis',
    sortOrder: 8,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002084',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Connective Tissue Diseases',
    slug: 'connective-tissue-diseases',
    sortOrder: 9,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002085',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Autoinflammatory Disorders',
    slug: 'autoinflammatory-disorders',
    sortOrder: 10,
  ),
  // Medicine > Rheumatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002086',
    parentUuid: '10000000-0000-5000-8000-000000000108',
    title: 'Rheumatological Emergencies',
    slug: 'rheumatological-emergencies',
    sortOrder: 11,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002087',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Approach to Infectious Syndromes',
    slug: 'approach-to-infectious-syndromes',
    sortOrder: 0,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002088',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'HIV Medicine',
    slug: 'hiv-medicine',
    sortOrder: 1,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002089',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Malaria and Other Parasitic Diseases',
    slug: 'malaria-and-other-parasitic-diseases',
    sortOrder: 2,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002090',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Tuberculosis and Mycobacterial Disease',
    slug: 'tuberculosis-and-mycobacterial-disease',
    sortOrder: 3,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002091',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Bacterial Infections',
    slug: 'bacterial-infections',
    sortOrder: 4,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002092',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Viral Infections',
    slug: 'viral-infections',
    sortOrder: 5,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002093',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Fungal Infections',
    slug: 'fungal-infections',
    sortOrder: 6,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002094',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Tropical and Travel-Related Infections',
    slug: 'tropical-and-travel-related-infections',
    sortOrder: 7,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002095',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Sepsis and Systemic Infection',
    slug: 'sepsis-and-systemic-infection',
    sortOrder: 8,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002096',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Antimicrobial Stewardship',
    slug: 'antimicrobial-stewardship',
    sortOrder: 9,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002097',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Healthcare-Associated Infections',
    slug: 'healthcare-associated-infections',
    sortOrder: 10,
  ),
  // Medicine > Infectious Diseases
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002098',
    parentUuid: '10000000-0000-5000-8000-000000000109',
    title: 'Infections in Immunocompromised Hosts',
    slug: 'infections-in-immunocompromised-hosts',
    sortOrder: 11,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002099',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Approach to Skin Lesions and Rashes',
    slug: 'approach-to-skin-lesions-and-rashes',
    sortOrder: 0,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002100',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Eczema and Dermatitis',
    slug: 'eczema-and-dermatitis',
    sortOrder: 1,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002101',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Papulosquamous Disorders',
    slug: 'papulosquamous-disorders',
    sortOrder: 2,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002102',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Acne and Rosacea',
    slug: 'acne-and-rosacea',
    sortOrder: 3,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002103',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Bacterial Skin Infections',
    slug: 'bacterial-skin-infections',
    sortOrder: 4,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002104',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Viral and Fungal Skin Infections',
    slug: 'viral-and-fungal-skin-infections',
    sortOrder: 5,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002105',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Parasitic Skin Diseases',
    slug: 'parasitic-skin-diseases',
    sortOrder: 6,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002106',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Drug Eruptions',
    slug: 'drug-eruptions',
    sortOrder: 7,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002107',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Autoimmune and Blistering Skin Disorders',
    slug: 'autoimmune-and-blistering-skin-disorders',
    sortOrder: 8,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002108',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Pigmentary Disorders',
    slug: 'pigmentary-disorders',
    sortOrder: 9,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002109',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Hair and Nail Disorders',
    slug: 'hair-and-nail-disorders',
    sortOrder: 10,
  ),
  // Medicine > Dermatology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002110',
    parentUuid: '10000000-0000-5000-8000-000000000110',
    title: 'Skin Tumours and Malignancies',
    slug: 'skin-tumours-and-malignancies',
    sortOrder: 11,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002111',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Primary Immunodeficiency',
    slug: 'primary-immunodeficiency',
    sortOrder: 0,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002112',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Secondary Immunodeficiency',
    slug: 'secondary-immunodeficiency',
    sortOrder: 1,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002113',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Hypersensitivity and Allergic Disorders',
    slug: 'hypersensitivity-and-allergic-disorders',
    sortOrder: 2,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002114',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Anaphylaxis',
    slug: 'anaphylaxis',
    sortOrder: 3,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002115',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Allergic Rhinitis and Conjunctivitis',
    slug: 'allergic-rhinitis-and-conjunctivitis',
    sortOrder: 4,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002116',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Food and Drug Allergy',
    slug: 'food-and-drug-allergy',
    sortOrder: 5,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002117',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Asthma and Allergy',
    slug: 'asthma-and-allergy',
    sortOrder: 6,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002118',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Urticaria and Angioedema',
    slug: 'urticaria-and-angioedema',
    sortOrder: 7,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002119',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Autoimmune Disease',
    slug: 'autoimmune-disease',
    sortOrder: 8,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002120',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Immunological Investigations',
    slug: 'immunological-investigations',
    sortOrder: 9,
  ),
  // Medicine > Clinical Immunology and Allergy
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002121',
    parentUuid: '10000000-0000-5000-8000-000000000111',
    title: 'Immunomodulatory Therapies',
    slug: 'immunomodulatory-therapies',
    sortOrder: 10,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002122',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Comprehensive Geriatric Assessment',
    slug: 'comprehensive-geriatric-assessment',
    sortOrder: 0,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002123',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Frailty and Functional Decline',
    slug: 'frailty-and-functional-decline',
    sortOrder: 1,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002124',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Falls and Mobility Disorders',
    slug: 'falls-and-mobility-disorders',
    sortOrder: 2,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002125',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Cognitive Impairment and Dementia',
    slug: 'cognitive-impairment-and-dementia',
    sortOrder: 3,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002126',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Delirium',
    slug: 'delirium',
    sortOrder: 4,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002127',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Polypharmacy and Deprescribing',
    slug: 'polypharmacy-and-deprescribing',
    sortOrder: 5,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002128',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Urinary and Faecal Incontinence',
    slug: 'urinary-and-faecal-incontinence',
    sortOrder: 6,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002129',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Nutrition and Frailty',
    slug: 'nutrition-and-frailty',
    sortOrder: 7,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002130',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Osteoporosis and Fragility Fractures',
    slug: 'osteoporosis-and-fragility-fractures',
    sortOrder: 8,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002131',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Multimorbidity and Complex Care',
    slug: 'multimorbidity-and-complex-care',
    sortOrder: 9,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002132',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Palliative and End-of-Life Care',
    slug: 'palliative-and-end-of-life-care',
    sortOrder: 10,
  ),
  // Medicine > Geriatric Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000002133',
    parentUuid: '10000000-0000-5000-8000-000000000112',
    title: 'Elder Abuse and Safeguarding',
    slug: 'elder-abuse-and-safeguarding',
    sortOrder: 11,
  ),

  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004001',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Physiological Changes in Pregnancy',
    slug: 'physiological-changes-in-pregnancy',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004002',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Antenatal Care',
    slug: 'antenatal-care',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004003',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Normal Labour and Delivery',
    slug: 'normal-labour-and-delivery',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004004',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Assessment of Labour Progress',
    slug: 'assessment-of-labour-progress',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004005',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Induction and Augmentation of Labour',
    slug: 'induction-and-augmentation-of-labour',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004006',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Operative Vaginal Delivery',
    slug: 'operative-vaginal-delivery',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004007',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Caesarean Birth',
    slug: 'caesarean-birth',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004008',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Postpartum Care',
    slug: 'postpartum-care',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004009',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Obstetric Emergencies',
    slug: 'obstetric-emergencies',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004010',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Obstetric Haemorrhage',
    slug: 'obstetric-haemorrhage',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004011',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Hypertensive Disorders of Pregnancy',
    slug: 'hypertensive-disorders-of-pregnancy',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004012',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Medical Disorders in Pregnancy',
    slug: 'medical-disorders-in-pregnancy',
    sortOrder: 11,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004013',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Preterm Labour and Birth',
    slug: 'preterm-labour-and-birth',
    sortOrder: 12,
  ),
  // Obstetrics and Gynaecology > Obstetrics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004014',
    parentUuid: '10000000-0000-5000-8000-000000000301',
    title: 'Prolonged and Obstructed Labour',
    slug: 'prolonged-and-obstructed-labour',
    sortOrder: 13,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004015',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Menstrual Disorders',
    slug: 'menstrual-disorders',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004016',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Abnormal Uterine Bleeding',
    slug: 'abnormal-uterine-bleeding',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004017',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Amenorrhoea',
    slug: 'amenorrhoea',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004018',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Dysmenorrhoea and Pelvic Pain',
    slug: 'dysmenorrhoea-and-pelvic-pain',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004019',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Endometriosis and Adenomyosis',
    slug: 'endometriosis-and-adenomyosis',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004020',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Uterine Fibroids',
    slug: 'uterine-fibroids',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004021',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Ovarian Cysts and Adnexal Masses',
    slug: 'ovarian-cysts-and-adnexal-masses',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004022',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Vaginal and Vulval Disorders',
    slug: 'vaginal-and-vulval-disorders',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004023',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Pelvic Inflammatory Disease',
    slug: 'pelvic-inflammatory-disease',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004024',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Gynaecological Infections',
    slug: 'gynaecological-infections',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004025',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Benign Gynaecological Conditions',
    slug: 'benign-gynaecological-conditions',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004026',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Gynaecological Procedures',
    slug: 'gynaecological-procedures',
    sortOrder: 11,
  ),
  // Obstetrics and Gynaecology > Gynaecology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004027',
    parentUuid: '10000000-0000-5000-8000-000000000302',
    title: 'Acute Gynaecological Presentations',
    slug: 'acute-gynaecological-presentations',
    sortOrder: 12,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004028',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'High-Risk Pregnancy Assessment',
    slug: 'high-risk-pregnancy-assessment',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004029',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Fetal Growth Restriction',
    slug: 'fetal-growth-restriction',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004030',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Multiple Pregnancy',
    slug: 'multiple-pregnancy',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004031',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Fetal Anomalies',
    slug: 'fetal-anomalies',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004032',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Fetal Surveillance',
    slug: 'fetal-surveillance',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004033',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Placental Disorders',
    slug: 'placental-disorders',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004034',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Preterm Birth Risk',
    slug: 'preterm-birth-risk',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004035',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Maternal Medical Disorders',
    slug: 'maternal-medical-disorders',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004036',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Rh Alloimmunisation',
    slug: 'rh-alloimmunisation',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004037',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Amniotic Fluid Disorders',
    slug: 'amniotic-fluid-disorders',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004038',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Cervical Insufficiency',
    slug: 'cervical-insufficiency',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Maternal-Fetal Medicine
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004039',
    parentUuid: '10000000-0000-5000-8000-000000000303',
    title: 'Perinatal Loss and Counselling',
    slug: 'perinatal-loss-and-counselling',
    sortOrder: 11,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004040',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Infertility Assessment',
    slug: 'infertility-assessment',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004041',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Female Infertility',
    slug: 'female-infertility',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004042',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Male Factor Infertility',
    slug: 'male-factor-infertility',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004043',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Ovulatory Disorders',
    slug: 'ovulatory-disorders',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004044',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Tubal and Peritoneal Factors',
    slug: 'tubal-and-peritoneal-factors',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004045',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Uterine Factors',
    slug: 'uterine-factors',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004046',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Ovarian Reserve Assessment',
    slug: 'ovarian-reserve-assessment',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004047',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Assisted Reproductive Technologies',
    slug: 'assisted-reproductive-technologies',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004048',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Recurrent Pregnancy Loss',
    slug: 'recurrent-pregnancy-loss',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004049',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Sexual Dysfunction and Fertility',
    slug: 'sexual-dysfunction-and-fertility',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004050',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Fertility Preservation',
    slug: 'fertility-preservation',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Reproductive Medicine and Infertility
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004051',
    parentUuid: '10000000-0000-5000-8000-000000000304',
    title: 'Reproductive Endocrinology',
    slug: 'reproductive-endocrinology',
    sortOrder: 11,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004052',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Cervical Cancer',
    slug: 'cervical-cancer',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004053',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Endometrial Cancer',
    slug: 'endometrial-cancer',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004054',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Ovarian Cancer',
    slug: 'ovarian-cancer',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004055',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Vulval and Vaginal Cancer',
    slug: 'vulval-and-vaginal-cancer',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004056',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Gestational Trophoblastic Disease',
    slug: 'gestational-trophoblastic-disease',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004057',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Premalignant Gynaecological Lesions',
    slug: 'premalignant-gynaecological-lesions',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004058',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Cancer Staging and Work-Up',
    slug: 'cancer-staging-and-work-up',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004059',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Surgical Management',
    slug: 'surgical-management',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004060',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Systemic and Radiation Treatment Coordination',
    slug: 'systemic-and-radiation-treatment-coordination',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004061',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Cancer Screening and Prevention',
    slug: 'cancer-screening-and-prevention',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004062',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Survivorship and Follow-Up',
    slug: 'survivorship-and-follow-up',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Gynaecological Oncology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004063',
    parentUuid: '10000000-0000-5000-8000-000000000305',
    title: 'Palliative Care',
    slug: 'palliative-care',
    sortOrder: 11,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004064',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Urinary Incontinence',
    slug: 'urinary-incontinence',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004065',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Pelvic Organ Prolapse',
    slug: 'pelvic-organ-prolapse',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004066',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Overactive Bladder',
    slug: 'overactive-bladder',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004067',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Voiding Dysfunction',
    slug: 'voiding-dysfunction',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004068',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Recurrent Urinary Tract Infections',
    slug: 'recurrent-urinary-tract-infections',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004069',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Pelvic Floor Dysfunction',
    slug: 'pelvic-floor-dysfunction',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004070',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Obstetric Pelvic Floor Injury',
    slug: 'obstetric-pelvic-floor-injury',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004071',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Urogenital Fistula',
    slug: 'urogenital-fistula',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004072',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Urogynaecological Assessment',
    slug: 'urogynaecological-assessment',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004073',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Conservative and Surgical Management',
    slug: 'conservative-and-surgical-management',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Urogynaecology and Pelvic Floor
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004074',
    parentUuid: '10000000-0000-5000-8000-000000000306',
    title: 'Postoperative Follow-Up',
    slug: 'postoperative-follow-up',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004075',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Contraceptive Counselling',
    slug: 'contraceptive-counselling',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004076',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Combined Hormonal Contraception',
    slug: 'combined-hormonal-contraception',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004077',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Progestogen-Only Methods',
    slug: 'progestogen-only-methods',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004078',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Intrauterine Contraception',
    slug: 'intrauterine-contraception',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004079',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Implants and Injectable Contraception',
    slug: 'implants-and-injectable-contraception',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004080',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Barrier and Fertility-Awareness Methods',
    slug: 'barrier-and-fertility-awareness-methods',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004081',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Emergency Contraception',
    slug: 'emergency-contraception',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004082',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Postpartum and Post-Abortion Contraception',
    slug: 'postpartum-and-post-abortion-contraception',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004083',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Contraception in Special Populations',
    slug: 'contraception-in-special-populations',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004084',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Management of Contraceptive Adverse Effects',
    slug: 'management-of-contraceptive-adverse-effects',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Family Planning and Contraception
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004085',
    parentUuid: '10000000-0000-5000-8000-000000000307',
    title: 'Permanent Contraception',
    slug: 'permanent-contraception',
    sortOrder: 10,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004086',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Sexual History and Assessment',
    slug: 'sexual-history-and-assessment',
    sortOrder: 0,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004087',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Sexually Transmitted Infections',
    slug: 'sexually-transmitted-infections',
    sortOrder: 1,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004088',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'HIV and Reproductive Health',
    slug: 'hiv-and-reproductive-health',
    sortOrder: 2,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004089',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Cervical Screening',
    slug: 'cervical-screening',
    sortOrder: 3,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004090',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Vulvovaginal Symptoms',
    slug: 'vulvovaginal-symptoms',
    sortOrder: 4,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004091',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Sexual Pain and Dysfunction',
    slug: 'sexual-pain-and-dysfunction',
    sortOrder: 5,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004092',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Menopause and Midlife Health',
    slug: 'menopause-and-midlife-health',
    sortOrder: 6,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004093',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Adolescent Reproductive Health',
    slug: 'adolescent-reproductive-health',
    sortOrder: 7,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004094',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Preconception Care',
    slug: 'preconception-care',
    sortOrder: 8,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004095',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Safe and Respectful Reproductive Care',
    slug: 'safe-and-respectful-reproductive-care',
    sortOrder: 9,
  ),
  // Obstetrics and Gynaecology > Reproductive and Sexual Health
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000004096',
    parentUuid: '10000000-0000-5000-8000-000000000308',
    title: 'Sexual Health after Cancer Treatment',
    slug: 'sexual-health-after-cancer-treatment',
    sortOrder: 10,
  ),

  // Dental > Periodontology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007001',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal Anatomy and Classification',
    slug: 'periodontal-anatomy-and-classification',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007002',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Gingival Conditions',
    slug: 'gingival-conditions',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007003',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontitis',
    slug: 'periodontitis',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007004',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal Examination',
    slug: 'periodontal-examination',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007005',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal Instrumentation',
    slug: 'periodontal-instrumentation',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007006',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Non-Surgical Periodontal Therapy',
    slug: 'non-surgical-periodontal-therapy',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007007',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Surgical Periodontal Therapy',
    slug: 'surgical-periodontal-therapy',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007008',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal Regeneration',
    slug: 'periodontal-regeneration',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007009',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal-Systemic Relationships',
    slug: 'periodontal-systemic-relationships',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007010',
    parentUuid: '10000000-0000-5000-8000-000000000601',
    title: 'Periodontal Maintenance',
    slug: 'periodontal-maintenance',
    sortOrder: 9,
  ),
  // Dental > Oral Pathology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007011',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Mucosal Lesions',
    slug: 'oral-mucosal-lesions',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007012',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Potentially Malignant Disorders',
    slug: 'oral-potentially-malignant-disorders',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007013',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Cysts',
    slug: 'oral-cysts',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007014',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Odontogenic Tumours',
    slug: 'odontogenic-tumours',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007015',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral and Maxillofacial Tumours',
    slug: 'oral-and-maxillofacial-tumours',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007016',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Salivary Gland Pathology',
    slug: 'salivary-gland-pathology',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007017',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Bone Pathology of the Jaws',
    slug: 'bone-pathology-of-the-jaws',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007018',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Manifestations of Systemic Disease',
    slug: 'oral-manifestations-of-systemic-disease',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007019',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Biopsy and Histopathology',
    slug: 'oral-biopsy-and-histopathology',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007020',
    parentUuid: '10000000-0000-5000-8000-000000000602',
    title: 'Oral Pathology Reporting',
    slug: 'oral-pathology-reporting',
    sortOrder: 9,
  ),
  // Dental > Oral and Maxillofacial Radiology
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007021',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Radiographic Principles and Safety',
    slug: 'radiographic-principles-and-safety',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007022',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Intraoral Imaging',
    slug: 'intraoral-imaging',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007023',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Panoramic Imaging',
    slug: 'panoramic-imaging',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007024',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Cone-Beam CT',
    slug: 'cone-beam-ct',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007025',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Dental Caries Imaging',
    slug: 'dental-caries-imaging',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007026',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Periodontal Imaging',
    slug: 'periodontal-imaging',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007027',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Endodontic Imaging',
    slug: 'endodontic-imaging',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007028',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Jaw Lesion Imaging',
    slug: 'jaw-lesion-imaging',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007029',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Trauma Imaging',
    slug: 'trauma-imaging',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007030',
    parentUuid: '10000000-0000-5000-8000-000000000603',
    title: 'Radiographic Interpretation and Reporting',
    slug: 'radiographic-interpretation-and-reporting',
    sortOrder: 9,
  ),
  // Dental > Paediatric Dentistry
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007031',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Child Oral Development',
    slug: 'child-oral-development',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007032',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Dental Caries in Children',
    slug: 'dental-caries-in-children',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007033',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Prevention and Fluoride',
    slug: 'prevention-and-fluoride',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007034',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Behaviour Guidance',
    slug: 'behaviour-guidance',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007035',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Restorative Dentistry in Children',
    slug: 'restorative-dentistry-in-children',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007036',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Pulp Therapy in Primary Teeth',
    slug: 'pulp-therapy-in-primary-teeth',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007037',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Dental Trauma in Children',
    slug: 'dental-trauma-in-children',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007038',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Developing Dentition',
    slug: 'developing-dentition',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007039',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Special Care Paediatric Dentistry',
    slug: 'special-care-paediatric-dentistry',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007040',
    parentUuid: '10000000-0000-5000-8000-000000000604',
    title: 'Paediatric Oral Pathology',
    slug: 'paediatric-oral-pathology',
    sortOrder: 9,
  ),
  // Dental > Orthodontics
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007041',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Craniofacial Growth and Development',
    slug: 'craniofacial-growth-and-development',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007042',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Occlusion and Malocclusion',
    slug: 'occlusion-and-malocclusion',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007043',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Orthodontic Diagnosis and Records',
    slug: 'orthodontic-diagnosis-and-records',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007044',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Cephalometric Analysis',
    slug: 'cephalometric-analysis',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007045',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Interceptive Orthodontics',
    slug: 'interceptive-orthodontics',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007046',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Fixed Appliance Therapy',
    slug: 'fixed-appliance-therapy',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007047',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Removable Appliance Therapy',
    slug: 'removable-appliance-therapy',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007048',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Orthodontic Biomechanics',
    slug: 'orthodontic-biomechanics',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007049',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Cleft Lip and Palate',
    slug: 'cleft-lip-and-palate',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007050',
    parentUuid: '10000000-0000-5000-8000-000000000605',
    title: 'Retention and Relapse',
    slug: 'retention-and-relapse',
    sortOrder: 9,
  ),
  // Dental > Conservative Dentistry
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007051',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Dental Caries and Risk Assessment',
    slug: 'dental-caries-and-risk-assessment',
    sortOrder: 0,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007052',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Cavity Preparation',
    slug: 'cavity-preparation',
    sortOrder: 1,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007053',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Direct Restorative Materials',
    slug: 'direct-restorative-materials',
    sortOrder: 2,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007054',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Adhesive Dentistry',
    slug: 'adhesive-dentistry',
    sortOrder: 3,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007055',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Pulp Biology and Diagnosis',
    slug: 'pulp-biology-and-diagnosis',
    sortOrder: 4,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007056',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Vital Pulp Therapy',
    slug: 'vital-pulp-therapy',
    sortOrder: 5,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007057',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Root Canal Treatment',
    slug: 'root-canal-treatment',
    sortOrder: 6,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007058',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Endodontic Complications',
    slug: 'endodontic-complications',
    sortOrder: 7,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007059',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Tooth Wear and Erosion',
    slug: 'tooth-wear-and-erosion',
    sortOrder: 8,
  ),
  InitialTaxonomyTopic(
    uuid: '10000000-0000-5000-8000-000000007060',
    parentUuid: '10000000-0000-5000-8000-000000000606',
    title: 'Restoration Repair and Replacement',
    slug: 'restoration-repair-and-replacement',
    sortOrder: 9,
  ),
];
