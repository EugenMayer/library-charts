{{/*
"toYaml" makes sure that any type of data (int/float/strin)
will be parsed correctly without causing errors.
*/}}
{{- define "ix.v1.common.container.fixedEnvs" -}}
  {{- $root := .root -}}
  {{- $containerName := .containerName -}}
  {{- $isMainContainer := .isMainContainer -}}
  {{- $security := .security -}}
  {{- $secCont := .secCont -}}

  {{- $podSecCont := $root.Values.podSecurityContext -}}
  {{- $defaultSecCont := $root.Values.global.defaults.securityContext -}}
  {{- $defaultPodSecCont := $root.Values.global.defaults.podSecurityContext -}}

  {{- if and $secCont.inherit (not $isMainContainer) -}} {{/* if inherit is set, use the secContext from main container as default */}}
    {{- $secCont = $root.Values.securityContext -}}
  {{- end -}}

  {{/* Init Values */}}
  {{- $runAsNonRoot := $defaultSecCont.runAsNonRoot -}}
  {{- $runAsUser := $defaultSecCont.runAsUser -}}
  {{- $runAsGroup := $defaultSecCont.runAsGroup -}}
  {{- $readOnlyRootFilesystem := $defaultSecCont.readOnlyRootFilesystem -}}
  {{- $fsGroup := $defaultPodSecCont.fsGroup -}}
  {{- $UMASK := $root.Values.global.defaults.security.UMASK -}}
  {{- $PUID := $root.Values.global.defaults.security.PUID -}}

  {{/* Override based on user/dev input */}}
  {{- if (hasKey $secCont "runAsNonRoot") -}}
    {{- if not (kindIs "bool" $secCont.runAsNonRoot) -}}
      {{- fail (printf "<runAsNonRoot> key has value (%v). But it must be boolean." $secCont.runAsNonRoot) -}}
    {{- else if or (eq $secCont.runAsNonRoot true) (eq $secCont.runAsNonRoot false) -}}
      {{- $runAsNonRoot = $secCont.runAsNonRoot -}}
    {{- end -}}
  {{- end -}}

  {{- if (hasKey $secCont "readOnlyRootFilesystem") -}}
    {{- if not (kindIs "bool" $secCont.readOnlyRootFilesystem) -}}
      {{- fail (printf "<readOnlyRootFilesystem> key has value (%v). But it must be boolean." $secCont.readOnlyRootFilesystem) -}}
    {{- else if or (eq $secCont.readOnlyRootFilesystem true) (eq $secCont.readOnlyRootFilesystem false) -}}
      {{- $readOnlyRootFilesystem = $secCont.readOnlyRootFilesystem -}}
    {{- end -}}
  {{- end -}}

  {{- if (hasKey $secCont "runAsUser") -}}
    {{- if eq (toString $secCont.runAsUser) "<nil>" -}}
      {{- fail (printf "<runAsUser> key cannot be empty. Set a value or remove the key for the default (%v) to take effect." $runAsUser) -}}
    {{- else if ge (int $secCont.runAsUser) 0 -}}
      {{- $runAsUser = $secCont.runAsUser -}}
    {{- end -}}
  {{- end -}}

  {{- if (hasKey $secCont "runAsGroup") -}}
    {{- if eq (toString $secCont.runAsGroup) "<nil>" -}}
      {{- fail (printf "<runAsGroup> key cannot be empty. Set a value or remove the key for the default (%v) to take effect." $runAsGroup) -}}
    {{- else if ge (int $secCont.runAsGroup) 0 -}}
      {{- $runAsGroup = $secCont.runAsGroup -}}
    {{- end -}}
  {{- end -}}

  {{- if (hasKey $podSecCont "fsGroup") -}}
    {{- if eq (toString $podSecCont.fsGroup) "<nil>" -}}
      {{- fail (printf "<fsGroup> key cannot be empty. Set a value or remove the key for the default (%v) to take effect." $fsGroup) -}}
    {{- else if ge (int $podSecCont.fsGroup) 0 -}}
      {{- $fsGroup = $podSecCont.fsGroup -}}
    {{- end -}}
  {{- end -}}

  {{- if (hasKey $security "UMASK") -}}
    {{- if not $security.UMASK -}}
      {{- fail (printf "<UMASK> key cannot be empty. Set a value or remove the key for the default (%v) to take effect." $UMASK) -}}
    {{- else if not (kindIs "string" $security.UMASK) -}}
      {{- fail (printf "<UMASK> key must be a string, so the format is kept intact.") -}}
    {{- else if $security.UMASK -}}
      {{- $UMASK = (tpl $security.UMASK $root) -}}
    {{- end -}}
  {{- end -}}

  {{/* TODO: Extract this checks into a function, but instead of returning the value, just print it (Test how it works with bools/ints) */}}
  {{- if (hasKey $security "PUID") -}}
    {{- if eq (toString $security.PUID) "<nil>" -}}
      {{- fail (printf "<PUID> key cannot be empty. Set a value or remove the key for the default (%v) to take effect." $PUID) -}}
    {{- else if not (mustHas (kindOf $security.PUID) (list "int" "float64")) -}}
      {{- fail "<PUID> key must be an int." -}}
    {{- else if ge (int $security.PUID) 0 -}}
      {{- $PUID = $security.PUID -}}
    {{- end -}}
  {{- end -}}

  {{- $vars := list -}}
  {{/* TODO: container aware NVIDIA Caps*/}}
  {{/* TODO: Convert this to yaml directly */}}
  {{- $vars = mustAppend $vars (dict "name" "TZ" "value" (tpl (toYaml $root.Values.TZ) $root)) -}}
  {{- $vars = mustAppend $vars (dict "name" "UMASK" "value" $UMASK) -}}
  {{- $vars = mustAppend $vars (dict "name" "UMASK_SET" "value" $UMASK) -}}
  {{- if not ($root.Values.scaleGPU) -}} {{/* TODO: container aware GPU */}}
    {{- $vars = mustAppend $vars (dict "name" "NVIDIA_VISIBLE_DEVICES" "value" "void") -}}
  {{- else -}}
    {{- $vars = mustAppend $vars (dict "name" "NVIDIA_DRIVER_CAPABILITIES" "value" (join "," $root.Values.nvidiaCaps)) -}}
  {{- end -}}
  {{- if and (or (eq ($runAsUser | int) 0) (eq ($runAsGroup | int) 0)) (ge ($PUID | int) 0) -}} {{/* If root user or root group and a PUID is set, set PUID and related envs */}}
    {{- $vars = mustAppend $vars (dict "name" "PUID" "value" $PUID) -}}
    {{- $vars = mustAppend $vars (dict "name" "USER_ID" "value" $PUID) -}}
    {{- $vars = mustAppend $vars (dict "name" "UID" "value" $PUID) -}}
    {{- $vars = mustAppend $vars (dict "name" "PGID" "value" $fsGroup) -}}
    {{- $vars = mustAppend $vars (dict "name" "GROUP_ID" "value" $fsGroup) -}}
    {{- $vars = mustAppend $vars (dict "name" "GID" "value" $fsGroup) -}}
  {{- end -}}
  {{- if or ($readOnlyRootFilesystem) ($runAsNonRoot) -}} {{/* Mainly for LSIO containers, tell S6 to avoid using rootfs */}}
    {{- $vars = mustAppend $vars (dict "name" "S6_READ_ONLY_ROOT" "value" "1") -}}
  {{- end -}}
  {{- include "ix.v1.common.util.storeEnvsForDupeCheck" (dict "root" $root "source" "fixedEnv" "data" (toJson $vars) "containers" (list $containerName)) -}}
  {{- toJson $vars -}} {{/* Helm can only return "string", so we stringify the output */}}
{{- end -}}
