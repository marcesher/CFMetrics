<cfscript>
publisher = new publishers.VariablePublisher();
collector = new cfmetrics.MetricsCollector(1, [ publisher ]);
query = collector.getMetricsDataFromDebugger();
writeDump(query);
</cfscript>
