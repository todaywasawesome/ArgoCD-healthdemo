hs = {}
hs.status = "Healthy"
hs.message = "ConfigMap ok"
if obj.metadata.labels ~= nil and obj.metadata.labels["healthdemo/check"] == "true" then
  if obj.data ~= nil and obj.data.DEMO_STATE == "broken" then
    hs.status = "Degraded"
    hs.message = "DEMO_STATE is broken: set it to ok and sync again"
  end
end
return hs
