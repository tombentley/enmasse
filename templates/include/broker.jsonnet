local common = import "common.jsonnet";
{
  container(volumeName, image_repo, addressEnv)::
    {
      "name": "broker",
      "image": image_repo,
      "ports": [
        common.container_port("amqp", 5673),
        common.container_port("jolokia", 8161)
      ],
      "env": [
        addressEnv,
        common.env("CLUSTER_ID", "${CLUSTER_ID}"),
        common.env("CERT_DIR", "/etc/enmasse-certs")
      ],
      "volumeMounts": [
        common.volume_mount(volumeName, "/var/run/artemis"),
        common.volume_mount("broker-internal-cert", "/etc/enmasse-certs", true),
        common.volume_mount("authservice-ca", "/etc/authservice-ca", true)
      ],
      "livenessProbe": common.exec_probe(["sh", "-c", "$ARTEMIS_HOME/bin/probe.sh"], 120),
      "readinessProbe": common.exec_probe(["sh", "-c", "$ARTEMIS_HOME/bin/probe.sh"], 10),
      "lifecycle": {
        "preStop": {
          "exec": {
            "command": [
              "/shutdown-hook/shutdown-hook.sh"
           ]
          }
        }
      }
    },
}
