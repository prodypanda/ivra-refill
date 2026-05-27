const fs = require('fs');
let code = fs.readFileSync('lib/src/features/products/products_screen.dart', 'utf8');

const replacements = {
  "'Product Catalog'": "l10n.t('productsCatalogTitle')",
  "'Create product'": "l10n.t('productsBtnCreate')",
  "'No products in the catalog yet.'": "l10n.t('productsNoProducts')",
  "'Bottle volume'": "l10n.t('productsLabelBottleVolume')",
  "'Bidon volume'": "l10n.t('productsLabelBidonVolume')",
  "'Max refill limit'": "l10n.t('productsLabelMaxRefill')",
  "'Max bottle age'": "l10n.t('productsLabelMaxAge')",
  "'Low stock alert'": "l10n.t('productsLabelLowStock')",
  "'Edit product'": "l10n.t('productsBtnEdit')",
  "'SKU'": "l10n.t('productsLabelSku')",
  "'Name English'": "l10n.t('productsLabelNameEn')",
  "'Name French'": "l10n.t('productsLabelNameFr')",
  "'Name Arabic'": "l10n.t('productsLabelNameAr')",
  "'Name Italian'": "l10n.t('productsLabelNameIt')",
  "'Product Picture Path/URL'": "l10n.t('productsLabelImage')",
  "'assets/images/shampoo.png or network URL'": "l10n.t('productsLabelImageHint')",
  "'Bottle ml'": "l10n.t('productsLabelBottleMl')",
  "'Bidon ml'": "l10n.t('productsLabelBidonMl')",
  "'Max refills'": "l10n.t('productsLabelMaxRefills')",
  "'Max age days'": "l10n.t('productsLabelMaxAgeDays')",
  "'Low bottles'": "l10n.t('productsLabelLowBottles')",
  "'Low bidons'": "l10n.t('productsLabelLowBidons')",
  "Text(_isEditing ? 'Edit product' : 'Create product')": "Text(_isEditing ? l10n.t('productsDialogEditTitle') : l10n.t('productsDialogCreateTitle'))",
  "Text(_isEditing ? 'Save' : 'Create')": "Text(_isEditing ? l10n.t('btnSave') : l10n.t('btnCreate'))",
  "'Cancel'": "l10n.t('btnCancel')",
  "'Required'": "l10n.t('requiredField')",
  "'Enter a number'": "l10n.t('enterNumberError')"
};

for (const [k, v] of Object.entries(replacements)) {
  code = code.split(k).join(v);
}

// Add AppLocalizations import if missing
if (!code.includes('app_localizations.dart')) {
  code = code.replace("import '../../domain/models.dart';", "import '../../domain/models.dart';\nimport '../../l10n/app_localizations.dart';");
}

// Add l10n definition in ProductsScreen build
if (!code.includes('final l10n = AppLocalizations.of(context);')) {
  code = code.replace("Widget build(BuildContext context, WidgetRef ref) {", "Widget build(BuildContext context, WidgetRef ref) {\n    final l10n = AppLocalizations.of(context);");
}

// Add l10n definition in _ProductsTable build
if (!code.includes('final language = Localizations.localeOf(context).languageCode;')) {
   // Already has it, replace it or add after
} else {
   code = code.replace("final language = Localizations.localeOf(context).languageCode;", "final language = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context);");
}

// Add l10n definition in _ProductDialog build
code = code.replace(/Widget build\(BuildContext context\) \{\n    return AlertDialog/, "Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    return AlertDialog");

fs.writeFileSync('lib/src/features/products/products_screen.dart', code);
console.log('Replaced strings.');
