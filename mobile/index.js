/**
 * Wasel Mobile App Entry Point
 * @format
 *
 * RTL NOTE: I18nManager.forceRTL must be called before AppRegistry.registerComponent
 * so Android's native layout engine sees the correct direction on the very first render.
 * ES module `import` statements are hoisted by Babel regardless of source order, making
 * ordering unreliable. We use `require()` here because CommonJS require() executes in
 * the order it appears in the file, giving us a guaranteed synchronous sequence:
 *   1. Read persisted language from MMKV (synchronous)
 *   2. Call forceRTL if direction needs to change
 *   3. Install brand fonts (wraps StyleSheet.create — must precede App import)
 *   4. Register the app component
 */

const { AppRegistry, I18nManager } = require('react-native');
const { MMKV } = require('react-native-mmkv');

// Step 1 & 2: apply RTL before any component is registered.
// MMKV is the authoritative startup store; LanguageContext keeps it in sync
// with AsyncStorage on every language change and migrates existing values.
const _startupStorage = new MMKV({ id: 'wasel-startup' });
const _startupLang = _startupStorage.getString('wasel-language') ?? 'ar';
const _needsRTL = _startupLang === 'ar';
I18nManager.allowRTL(true);
// Guard the forceRTL call: calling it when the value hasn't changed triggers
// an unnecessary activity restart loop on some Android/RN version combinations.
if (I18nManager.isRTL !== _needsRTL) {
  I18nManager.forceRTL(_needsRTL);
}

// Step 3: must run before App is required so StyleSheet.create is already wrapped.
require('./src/styles/installFonts');

// Step 4: register.
const App = require('./src/App').default;
const appConfig = require('./app.json');

AppRegistry.registerComponent(appConfig.expo.name, () => App);
