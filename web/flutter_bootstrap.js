{{flutter_js}}
{{flutter_build_config}}

// Keep CanvasKit's overlay surface pool small without disabling GPU
// acceleration. If repeated hot restarts exhaust browser WebGL contexts, a
// full tab refresh releases the abandoned development engines.

_flutter.loader.load({
  config: {
    canvasKitMaximumSurfaces: 4,
  },
});
