hs = {}
hs.status = "Progressing"
hs.message = "Waiting for controller to reconcile"
if obj.status == nil then
  return hs
end
if obj.status.observedGeneration ~= nil and obj.metadata.generation ~= nil
   and obj.status.observedGeneration < obj.metadata.generation then
  hs.message = "Controller has not observed generation " .. obj.metadata.generation
  return hs
end
if obj.status.conditions ~= nil then
  for _, c in ipairs(obj.status.conditions) do
    if c.type == "Ready" then
      if c.status == "True" then
        hs.status = "Healthy"
        hs.message = c.message or "Ready"
        return hs
      elseif c.status == "False" then
        hs.status = "Degraded"
        hs.message = c.message or c.reason or "Not ready"
        return hs
      end
    end
  end
end
return hs
