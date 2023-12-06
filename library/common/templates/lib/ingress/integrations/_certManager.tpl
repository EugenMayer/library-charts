{{- define "tc.v1.common.lib.ingress.integration.certManager" -}}
  {{- $objectData := .objectData -}}
  {{- $rootCtx := .rootCtx -}}

  {{- $certManager := $objectData.integrations.certManager -}}

  {{- $enabled := false -}}
  {{- if (hasKey $rootCtx.Values.global "certManager") -}}
    {{- $enabled = $rootCtx.Values.global.certManager.addIngressAnnotations -}}
  {{- end -}}

  {{- if and $certManager (kindIs "bool" $certManager.enabled) -}}
    {{- $enabled = $certManager.enabled -}}
  {{- end -}}

  {{- if $enabled -}}
    {{- include "tc.v1.common.lib.ingress.integration.certManager.validate" (dict "objectData" $objectData) -}}

    {{- $_ := set $objectData.annotations "cert-manager.io/cluster-issuer" "TODO:" -}}
    {{- $_ := set $objectData.annotations "cert-manager.io/private-key-rotation-policy" "Always" -}}

  {{- end -}}
{{- end -}}

{{- define "tc.v1.common.lib.ingress.integration.certManager.validate" -}}
  {{- $objectData := .objectData -}}

  {{- $certManager := $objectData.integrations.certManager -}}

  {{- if $certManager -}}

  {{- end -}}
{{- end -}}
