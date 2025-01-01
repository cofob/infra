{ lib, nginx, nginxModules, modules ? [ ] }:

(nginx.override {
  modules = lib.unique
    (nginx.modules ++ [ nginxModules.brotli nginxModules.zstd ] ++ modules);
}).overrideAttrs (previousAttrs: {
  pname = "nginx-custom";
  patches = previousAttrs.patches ++ [ ./1-remove-version.patch ];
})
