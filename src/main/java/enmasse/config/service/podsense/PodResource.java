package enmasse.config.service.podsense;

import enmasse.config.service.model.Resource;
import io.fabric8.kubernetes.api.model.Container;
import io.fabric8.kubernetes.api.model.ContainerPort;
import io.fabric8.kubernetes.api.model.Pod;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Represents a podsense resource.
 */
public class PodResource extends Resource {
    private final String name;
    private final String kind;
    private final String host;
    private final String phase;
    private final Map<String, Map<String, Integer>> portMap;

    public PodResource(Pod pod) {
        this.name = pod.getMetadata().getName();
        this.kind = pod.getKind();
        this.host = pod.getStatus().getPodIP();
        this.phase = pod.getStatus().getPhase();
        this.portMap = getPortMap(pod.getSpec().getContainers());
    }

    private static Map<String, Map<String, Integer>> getPortMap(List<Container> containers) {
        Map<String, Map<String, Integer>> portMap = new LinkedHashMap<>();
        for (Container container : containers) {
            Map<String, Integer> ports = new LinkedHashMap<>();
            for (ContainerPort port : container.getPorts()) {
                ports.put(port.getName(), port.getContainerPort());
            }
            portMap.put(container.getName(), ports);
        }
        return portMap;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        PodResource that = (PodResource) o;

        if (!name.equals(that.name)) return false;
        if (!kind.equals(that.kind)) return false;
        if (host != null ? !host.equals(that.host) : that.host != null) return false;
        if (phase != null ? !phase.equals(that.phase) : that.phase != null) return false;
        return portMap != null ? portMap.equals(that.portMap) : that.portMap == null;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public String getKind() {
        return kind;
    }

    @Override
    public String toString() {
        return kind + ":" + name;
    }

    @Override
    public int hashCode() {
        int result = name.hashCode();
        result = 31 * result + kind.hashCode();
        result = 31 * result + (host != null ? host.hashCode() : 0);
        result = 31 * result + (phase != null ? phase.hashCode() : 0);
        result = 31 * result + (portMap != null ? portMap.hashCode() : 0);
        return result;
    }

    public String getPhase() {
        return phase;
    }

    public String getHost() {
        return host;
    }

    public Map<String, Map<String, Integer>> getPortMap() {
        return portMap;
    }
}
