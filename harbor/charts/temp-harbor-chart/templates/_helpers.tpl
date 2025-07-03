{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "temp-harbor-chart.name" -}}
{{- default "temp-harbor-chart" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "temp-harbor-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "temp-harbor-chart" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Helm required labels */}}
{{- define "temp-harbor-chart.labels" -}}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
chart: {{ .Chart.Name }}
app: "{{ template "temp-harbor-chart.name" . }}"
{{- end -}}

{{/* matchLabels */}}
{{- define "temp-harbor-chart.matchLabels" -}}
release: {{ .Release.Name }}
app: "{{ template "temp-harbor-chart.name" . }}"
{{- end -}}

{{- define "temp-harbor-chart.autoGenCert" -}}
  {{- if and .Values.expose.tls.enabled (eq .Values.expose.tls.certSource "auto") -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.autoGenCertForIngress" -}}
  {{- if and (eq (include "temp-harbor-chart.autoGenCert" .) "true") (eq .Values.expose.type "ingress") -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.autoGenCertForNginx" -}}
  {{- if and (eq (include "temp-harbor-chart.autoGenCert" .) "true") (ne .Values.expose.type "ingress") -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.host" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- template "temp-harbor-chart.database" . }}
  {{- else -}}
    {{- .Values.database.external.host -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.port" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "5432" -}}
  {{- else -}}
    {{- .Values.database.external.port -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.username" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "postgres" -}}
  {{- else -}}
    {{- .Values.database.external.username -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.rawPassword" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- .Values.database.internal.password -}}
  {{- else -}}
    {{- .Values.database.external.password -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.escapedRawPassword" -}}
  {{- include "temp-harbor-chart.database.rawPassword" . | urlquery | replace "+" "%20" -}}
{{- end -}}

{{- define "temp-harbor-chart.database.encryptedPassword" -}}
  {{- include "temp-harbor-chart.database.rawPassword" . | b64enc | quote -}}
{{- end -}}

{{- define "temp-harbor-chart.database.coreDatabase" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "registry" -}}
  {{- else -}}
    {{- .Values.database.external.coreDatabase -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.notaryServerDatabase" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "notaryserver" -}}
  {{- else -}}
    {{- .Values.database.external.notaryServerDatabase -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.notarySignerDatabase" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "notarysigner" -}}
  {{- else -}}
    {{- .Values.database.external.notarySignerDatabase -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.sslmode" -}}
  {{- if eq .Values.database.type "internal" -}}
    {{- printf "%s" "disable" -}}
  {{- else -}}
    {{- .Values.database.external.sslmode -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.database.notaryServer" -}}
postgres://{{ template "temp-harbor-chart.database.username" . }}:{{ template "temp-harbor-chart.database.escapedRawPassword" . }}@{{ template "temp-harbor-chart.database.host" . }}:{{ template "temp-harbor-chart.database.port" . }}/{{ template "temp-harbor-chart.database.notaryServerDatabase" . }}?sslmode={{ template "temp-harbor-chart.database.sslmode" . }}
{{- end -}}

{{- define "temp-harbor-chart.database.notarySigner" -}}
postgres://{{ template "temp-harbor-chart.database.username" . }}:{{ template "temp-harbor-chart.database.escapedRawPassword" . }}@{{ template "temp-harbor-chart.database.host" . }}:{{ template "temp-harbor-chart.database.port" . }}/{{ template "temp-harbor-chart.database.notarySignerDatabase" . }}?sslmode={{ template "temp-harbor-chart.database.sslmode" . }}
{{- end -}}

{{- define "temp-harbor-chart.redis.scheme" -}}
  {{- with .Values.redis }}
    {{- ternary "redis+sentinel" "redis"  (and (eq .type "external" ) (not (not .external.sentinelMasterSet))) }}
  {{- end }}
{{- end -}}

/*host:port*/
{{- define "temp-harbor-chart.redis.addr" -}}
  {{- with .Values.redis }}
    {{- ternary (printf "%s:6379" (include "temp-harbor-chart.redis" $ )) .external.addr (eq .type "internal") }}
  {{- end }}
{{- end -}}

{{- define "temp-harbor-chart.redis.masterSet" -}}
  {{- with .Values.redis }}
    {{- ternary .external.sentinelMasterSet "" (eq "redis+sentinel" (include "temp-harbor-chart.redis.scheme" $)) }}
  {{- end }}
{{- end -}}

{{- define "temp-harbor-chart.redis.password" -}}
  {{- with .Values.redis }}
    {{- ternary "" .external.password (eq .type "internal") }}
  {{- end }}
{{- end -}}

/*scheme://[redis:password@]host:port[/master_set]*/
{{- define "temp-harbor-chart.redis.url" -}}
  {{- with .Values.redis }}
    {{- $path := ternary "" (printf "/%s" (include "temp-harbor-chart.redis.masterSet" $)) (not (include "temp-harbor-chart.redis.masterSet" $)) }}
    {{- $cred := ternary (printf "redis:%s@" (.external.password | urlquery)) "" (and (eq .type "external" ) (not (not .external.password))) }}
    {{- printf "%s://%s%s%s" (include "temp-harbor-chart.redis.scheme" $) $cred (include "temp-harbor-chart.redis.addr" $) $path -}}
  {{- end }}
{{- end -}}

/*scheme://[redis:password@]addr/db_index?idle_timeout_seconds=30*/
{{- define "temp-harbor-chart.redis.urlForCore" -}}
  {{- with .Values.redis }}
    {{- $index := ternary "0" .external.coreDatabaseIndex (eq .type "internal") }}
    {{- printf "%s/%s?idle_timeout_seconds=30" (include "temp-harbor-chart.redis.url" $) $index -}}
  {{- end }}
{{- end -}}

/*scheme://[redis:password@]addr/db_index*/
{{- define "temp-harbor-chart.redis.urlForJobservice" -}}
  {{- with .Values.redis }}
    {{- $index := ternary "1" .external.jobserviceDatabaseIndex (eq .type "internal") }}
    {{- printf "%s/%s" (include "temp-harbor-chart.redis.url" $) $index -}}
  {{- end }}
{{- end -}}

/*scheme://[redis:password@]addr/db_index?idle_timeout_seconds=30*/
{{- define "temp-harbor-chart.redis.urlForRegistry" -}}
  {{- with .Values.redis }}
    {{- $index := ternary "2" .external.registryDatabaseIndex (eq .type "internal") }}
    {{- printf "%s/%s?idle_timeout_seconds=30" (include "temp-harbor-chart.redis.url" $) $index -}}
  {{- end }}
{{- end -}}

/*scheme://[redis:password@]addr/db_index?idle_timeout_seconds=30*/
{{- define "temp-harbor-chart.redis.urlForTrivy" -}}
  {{- with .Values.redis }}
    {{- $index := ternary "5" .external.trivyAdapterIndex (eq .type "internal") }}
    {{- printf "%s/%s?idle_timeout_seconds=30" (include "temp-harbor-chart.redis.url" $) $index -}}
  {{- end }}
{{- end -}}

{{- define "temp-harbor-chart.redis.dbForRegistry" -}}
  {{- with .Values.redis }}
    {{- ternary "2" .external.registryDatabaseIndex (eq .type "internal") }}
  {{- end }}
{{- end -}}

{{- define "temp-harbor-chart.redis.dbForChartmuseum" -}}
  {{- with .Values.redis }}
    {{- ternary "3" .external.chartmuseumDatabaseIndex (eq .type "internal") }}
  {{- end }}
{{- end -}}

{{- define "temp-harbor-chart.portal" -}}
  {{- printf "%s-portal" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.core" -}}
  {{- printf "%s-core" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.redis" -}}
  {{- printf "%s-redis" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.jobservice" -}}
  {{- printf "%s-jobservice" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.registry" -}}
  {{- printf "%s-registry" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.chartmuseum" -}}
  {{- printf "%s-chartmuseum" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.database" -}}
  {{- printf "%s-database" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.trivy" -}}
  {{- printf "%s-trivy" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.notary-server" -}}
  {{- printf "%s-notary-server" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.notary-signer" -}}
  {{- printf "%s-notary-signer" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.nginx" -}}
  {{- printf "%s-nginx" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.exporter" -}}
  {{- printf "%s-exporter" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.ingress" -}}
  {{- printf "%s-ingress" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.ingress-notary" -}}
  {{- printf "%s-ingress-notary" (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.noProxy" -}}
  {{- printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" (include "temp-harbor-chart.core" .) (include "temp-harbor-chart.jobservice" .) (include "temp-harbor-chart.database" .) (include "temp-harbor-chart.chartmuseum" .) (include "temp-harbor-chart.notary-server" .) (include "temp-harbor-chart.notary-signer" .) (include "temp-harbor-chart.registry" .) (include "temp-harbor-chart.portal" .) (include "temp-harbor-chart.trivy" .) (include "temp-harbor-chart.exporter" .) .Values.proxy.noProxy -}}
{{- end -}}

{{- define "temp-harbor-chart.caBundleVolume" -}}
- name: ca-bundle-certs
  secret:
    secretName: {{ .Values.caBundleSecretName }}
{{- end -}}

{{- define "temp-harbor-chart.caBundleVolumeMount" -}}
- name: ca-bundle-certs
  mountPath: /harbor_cust_cert/custom-ca.crt
  subPath: ca.crt
{{- end -}}

{{/* scheme for all components except notary because it only support http mode */}}
{{- define "temp-harbor-chart.component.scheme" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "https" -}}
  {{- else -}}
    {{- printf "http" -}}
  {{- end -}}
{{- end -}}

{{/* chartmuseum component container port */}}
{{- define "temp-harbor-chart.chartmuseum.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "9443" -}}
  {{- else -}}
    {{- printf "9999" -}}
  {{- end -}}
{{- end -}}

{{/* chartmuseum component service port */}}
{{- define "temp-harbor-chart.chartmuseum.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "443" -}}
  {{- else -}}
    {{- printf "80" -}}
  {{- end -}}
{{- end -}}

{{/* core component container port */}}
{{- define "temp-harbor-chart.core.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* core component service port */}}
{{- define "temp-harbor-chart.core.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "443" -}}
  {{- else -}}
    {{- printf "80" -}}
  {{- end -}}
{{- end -}}

{{/* jobservice component container port */}}
{{- define "temp-harbor-chart.jobservice.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* jobservice component service port */}}
{{- define "temp-harbor-chart.jobservice.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "443" -}}
  {{- else -}}
    {{- printf "80" -}}
  {{- end -}}
{{- end -}}

{{/* portal component container port */}}
{{- define "temp-harbor-chart.portal.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* portal component service port */}}
{{- define "temp-harbor-chart.portal.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "443" -}}
  {{- else -}}
    {{- printf "80" -}}
  {{- end -}}
{{- end -}}

{{/* registry component container port */}}
{{- define "temp-harbor-chart.registry.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "5443" -}}
  {{- else -}}
    {{- printf "5000" -}}
  {{- end -}}
{{- end -}}

{{/* registry component service port */}}
{{- define "temp-harbor-chart.registry.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "5443" -}}
  {{- else -}}
    {{- printf "5000" -}}
  {{- end -}}
{{- end -}}

{{/* registryctl component container port */}}
{{- define "temp-harbor-chart.registryctl.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* registryctl component service port */}}
{{- define "temp-harbor-chart.registryctl.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* trivy component container port */}}
{{- define "temp-harbor-chart.trivy.containerPort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* trivy component service port */}}
{{- define "temp-harbor-chart.trivy.servicePort" -}}
  {{- if .Values.internalTLS.enabled -}}
    {{- printf "8443" -}}
  {{- else -}}
    {{- printf "8080" -}}
  {{- end -}}
{{- end -}}

{{/* CORE_URL */}}
{{/* port is included in this url as a workaround for issue https://github.com/aquasecurity/harbor-scanner-trivy/issues/108 */}}
{{- define "temp-harbor-chart.coreURL" -}}
  {{- printf "%s://%s:%s" (include "temp-harbor-chart.component.scheme" .) (include "temp-harbor-chart.core" .) (include "temp-harbor-chart.core.servicePort" .) -}}
{{- end -}}

{{/* JOBSERVICE_URL */}}
{{- define "temp-harbor-chart.jobserviceURL" -}}
  {{- printf "%s://%s-jobservice" (include "temp-harbor-chart.component.scheme" .)  (include "temp-harbor-chart.fullname" .) -}}
{{- end -}}

{{/* PORTAL_URL */}}
{{- define "temp-harbor-chart.portalURL" -}}
  {{- printf "%s://%s" (include "temp-harbor-chart.component.scheme" .) (include "temp-harbor-chart.portal" .) -}}
{{- end -}}

{{/* REGISTRY_URL */}}
{{- define "temp-harbor-chart.registryURL" -}}
  {{- printf "%s://%s:%s" (include "temp-harbor-chart.component.scheme" .) (include "temp-harbor-chart.registry" .) (include "temp-harbor-chart.registry.servicePort" .) -}}
{{- end -}}

{{/* REGISTRY_CONTROLLER_URL */}}
{{- define "temp-harbor-chart.registryControllerURL" -}}
  {{- printf "%s://%s:%s" (include "temp-harbor-chart.component.scheme" .) (include "temp-harbor-chart.registry" .) (include "temp-harbor-chart.registryctl.servicePort" .) -}}
{{- end -}}

{{/* TOKEN_SERVICE_URL */}}
{{- define "temp-harbor-chart.tokenServiceURL" -}}
  {{- printf "%s/service/token" (include "temp-harbor-chart.coreURL" .) -}}
{{- end -}}

{{/* TRIVY_ADAPTER_URL */}}
{{- define "temp-harbor-chart.trivyAdapterURL" -}}
  {{- printf "%s://%s:%s" (include "temp-harbor-chart.component.scheme" .) (include "temp-harbor-chart.trivy" .) (include "temp-harbor-chart.trivy.servicePort" .) -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.chartmuseum.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.chartmuseum.secretName -}}
  {{- else -}}
    {{- printf "%s-chartmuseum-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.core.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.core.secretName -}}
  {{- else -}}
    {{- printf "%s-core-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.jobservice.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.jobservice.secretName -}}
  {{- else -}}
    {{- printf "%s-jobservice-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.portal.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.portal.secretName -}}
  {{- else -}}
    {{- printf "%s-portal-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.registry.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.registry.secretName -}}
  {{- else -}}
    {{- printf "%s-registry-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.internalTLS.trivy.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.trivy.secretName -}}
  {{- else -}}
    {{- printf "%s-trivy-internal-tls" (include "temp-harbor-chart.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.tlsCoreSecretForIngress" -}}
  {{- if eq .Values.expose.tls.certSource "none" -}}
    {{- printf "" -}}
  {{- else if eq .Values.expose.tls.certSource "secret" -}}
    {{- .Values.expose.tls.secret.secretName -}}
  {{- else -}}
    {{- include "temp-harbor-chart.ingress" . -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.tlsNotarySecretForIngress" -}}
  {{- if eq .Values.expose.tls.certSource "none" -}}
    {{- printf "" -}}
  {{- else if eq .Values.expose.tls.certSource "secret" -}}
    {{- .Values.expose.tls.secret.notarySecretName -}}
  {{- else -}}
    {{- include "temp-harbor-chart.ingress" . -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.tlsSecretForNginx" -}}
  {{- if eq .Values.expose.tls.certSource "secret" -}}
    {{- .Values.expose.tls.secret.secretName -}}
  {{- else -}}
    {{- include "temp-harbor-chart.nginx" . -}}
  {{- end -}}
{{- end -}}

{{- define "temp-harbor-chart.metricsPortName" -}}
  {{- if .Values.internalTLS.enabled }}
    {{- printf "https-metrics" -}}
  {{- else -}}
    {{- printf "http-metrics" -}}
  {{- end -}}
{{- end -}}