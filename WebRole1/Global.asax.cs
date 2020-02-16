using NewRelic.Api.Agent;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace WebRole1
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            var pollingThread = new Thread(DoPoll);
            pollingThread.IsBackground = true;
            pollingThread.Start();

            Application["DoPoll"] = pollingThread;
        }

        public void DoPoll()
        {
            while (true)
            {
                Trace.TraceInformation("Polling is running");
                Task.Delay(5000).GetAwaiter().GetResult();
                var workingTrhead = new Thread(DoWork);
                workingTrhead.IsBackground = true;
                workingTrhead.Start();
            }
        }

        [Transaction]
        private void DoWork()
        {
            Trace.TraceInformation("DoWork Started");
            Task.Delay(new Random().Next(5000)).GetAwaiter().GetResult();
        }

        protected void Application_End()
        {
            try
            {
                var pollingThread = (Thread)Application["DoPoll"];
                if (pollingThread != null && pollingThread.IsAlive)
                {
                    pollingThread.Abort();
                }
            }
            catch
            {
                ///
            }
        }
    }
}
