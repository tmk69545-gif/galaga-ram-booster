package com.galaga.ramhook;

import android.app.ActivityManager;
import android.widget.ProgressBar;
import android.widget.TextView;
import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;

public class HookInit implements IXposedHookLoadPackage {

    private static final long BOOST_RAM_BYTES = 8589934592L; // +8 GB (Total 16 GB)

    @Override
    public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam lpparam) throws Throwable {
        XposedBridge.log("[GalagaHook] Loaded into: " + lpparam.packageName);

        // 1. Hook ActivityManager.getMemoryInfo everywhere
        try {
            XposedHelpers.findAndHookMethod(
                ActivityManager.class,
                "getMemoryInfo",
                ActivityManager.MemoryInfo.class,
                new XC_MethodHook() {
                    @Override
                    protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                        ActivityManager.MemoryInfo info = (ActivityManager.MemoryInfo) param.args[0];
                        if (info != null) {
                            info.totalMem += BOOST_RAM_BYTES;
                            // Also adjust availMem so total - availMem doesn't falsely report 92%+ used
                            info.availMem += BOOST_RAM_BYTES;
                            XposedBridge.log("[GalagaHook] ActivityManager.getMemoryInfo boosted totalMem=" + info.totalMem + " availMem=" + info.availMem);
                        }
                    }
                }
            );
        } catch (Throwable t) {
            XposedBridge.log("[GalagaHook] Hook ActivityManager failed: " + t.getMessage());
        }

        // 2. Global TextView.setText(CharSequence) hook for exact text transformation
        try {
            XposedHelpers.findAndHookMethod(
                TextView.class,
                "setText",
                CharSequence.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                        CharSequence cs = (CharSequence) param.args[0];
                        if (cs != null) {
                            String str = cs.toString();
                            // Project Infinity X Settings: "8 GB (Active)" -> "8 GB + 8 GB (Active)"
                            if (str.equals("8 GB (Active)") || str.startsWith("8 GB (Active") || str.matches("^8\\s*GB\\s*\\(.*Active.*\\)$")) {
                                param.args[0] = "8 GB + 8 GB (Active)";
                                XposedBridge.log("[GalagaHook] Replaced Settings RAM text -> " + param.args[0]);
                            }
                            // Recents Panel in Launcher3:
                            // Format: "%1$s available | %2$s"
                            // If user sees "3.5 GB available | 7.8 GB" -> we can optionally boost available to "11.5 GB available | 16 GB"
                            else if (str.contains("available |") || str.contains("Available |")) {
                                // Match: "X.X GB available | Y.Y GB"
                                java.util.regex.Matcher m = java.util.regex.Pattern.compile("([0-9]+(?:\\.[0-9]+)?)\\s*GB\\s*(available\\s*\\|)\\s*([0-9]+(?:\\.[0-9]+)?)\\s*GB", java.util.regex.Pattern.CASE_INSENSITIVE).matcher(str);
                                if (m.find()) {
                                    try {
                                        double availGb = Double.parseDouble(m.group(1));
                                        double boostedAvail = availGb + 8.0; // Add 8 GB virtual pool
                                        String formatted = String.format(java.util.Locale.US, "%.1f GB %s 16 GB", boostedAvail, m.group(2));
                                        param.args[0] = formatted;
                                        XposedBridge.log("[GalagaHook] Replaced Recents RAM: " + str + " -> " + formatted);
                                    } catch (Throwable ignored) {
                                        param.args[0] = str.replaceAll("(?i)(\\|\\s*)(7\\.[0-9]|8\\.[0-9]|8)\\s*GB", "$116 GB");
                                    }
                                } else {
                                    param.args[0] = str.replaceAll("(?i)(\\|\\s*)(7\\.[0-9]|8\\.[0-9]|8)\\s*GB", "$116 GB");
                                }
                            }
                        }
                    }
                }
            );
        } catch (Throwable t) {
            XposedBridge.log("[GalagaHook] Hook TextView.setText(CharSequence) failed: " + t.getMessage());
        }

        // 3. TextView.setText(CharSequence, BufferType) hook
        try {
            XposedHelpers.findAndHookMethod(
                TextView.class,
                "setText",
                CharSequence.class,
                TextView.BufferType.class,
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                        CharSequence cs = (CharSequence) param.args[0];
                        if (cs != null) {
                            String str = cs.toString();
                            if (str.equals("8 GB (Active)") || str.startsWith("8 GB (Active") || str.matches("^8\\s*GB\\s*\\(.*Active.*\\)$")) {
                                param.args[0] = "8 GB + 8 GB (Active)";
                            } else if (str.contains("available |") || str.contains("Available |")) {
                                java.util.regex.Matcher m = java.util.regex.Pattern.compile("([0-9]+(?:\\.[0-9]+)?)\\s*GB\\s*(available\\s*\\|)\\s*([0-9]+(?:\\.[0-9]+)?)\\s*GB", java.util.regex.Pattern.CASE_INSENSITIVE).matcher(str);
                                if (m.find()) {
                                    try {
                                        double availGb = Double.parseDouble(m.group(1));
                                        double boostedAvail = availGb + 8.0;
                                        param.args[0] = String.format(java.util.Locale.US, "%.1f GB %s 16 GB", boostedAvail, m.group(2));
                                    } catch (Throwable ignored) {
                                        param.args[0] = str.replaceAll("(?i)(\\|\\s*)(7\\.[0-9]|8\\.[0-9]|8)\\s*GB", "$116 GB");
                                    }
                                } else {
                                    param.args[0] = str.replaceAll("(?i)(\\|\\s*)(7\\.[0-9]|8\\.[0-9]|8)\\s*GB", "$116 GB");
                                }
                            }
                        }
                    }
                }
            );
        } catch (Throwable t) {
            XposedBridge.log("[GalagaHook] Hook TextView.setText(CharSequence, BufferType) failed: " + t.getMessage());
        }

        // 4. Specific Hooks for Settings (com.android.settings.OosAboutPreference)
        if ("com.android.settings".equals(lpparam.packageName)) {
            try {
                Class<?> oosAboutClass = XposedHelpers.findClass("com.android.settings.OosAboutPreference", lpparam.classLoader);
                XposedBridge.hookAllMethods(oosAboutClass, "lambda$onBindItems$0", new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                        // Fix the RAM bar: adjust usedRamPercentage in MemoryInfo so it calculates out of 16GB (~28% green)
                        if (param.args != null && param.args.length >= 6) {
                            Object memInfo = param.args[4];
                            if (memInfo != null) {
                                try {
                                    // Set a healthy, realistic 28% memory utilization (green bar)
                                    XposedHelpers.setIntField(memInfo, "usedRamPercentage", 28);
                                    XposedBridge.log("[GalagaHook] Set usedRamPercentage to 28%");
                                } catch (Throwable t) {
                                    XposedBridge.log("[GalagaHook] Failed to set usedRamPercentage: " + t.getMessage());
                                }
                            }
                        }
                    }

                    @Override
                    protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                        if (param.args != null && param.args.length >= 4 && param.args[3] instanceof TextView) {
                            TextView ramView = (TextView) param.args[3];
                            ramView.setText("8 GB + 8 GB (Active)");
                            XposedBridge.log("[GalagaHook] Directly set OosAboutPreference RAM view to '8 GB + 8 GB (Active)'");
                        }
                    }
                });
            } catch (Throwable t) {
                XposedBridge.log("[GalagaHook] Direct OosAboutPreference hook failed: " + t.getMessage());
            }
        }
    }
}
