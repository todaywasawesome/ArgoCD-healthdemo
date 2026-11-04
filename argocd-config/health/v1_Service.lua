-- Same as the built-in Service check, but with an actionable message for LoadBalancers.
hs = {}
hs.status = "Healthy"
hs.message = "Service ok"
if obj.spec ~= nil and obj.spec.type == "LoadBalancer" then
  local ingress = nil
  if obj.status ~= nil and obj.status.loadBalancer ~= nil then
    ingress = obj.status.loadBalancer.ingress
  end
  if ingress == nil or #ingress == 0 then
    hs.status = "Progressing"
    hs.message = "Waiting for an external address: is a load balancer controller installed?"
  end
end
return hs
