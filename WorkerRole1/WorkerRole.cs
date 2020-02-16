using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.WindowsAzure;
using Microsoft.WindowsAzure.Diagnostics;
using Microsoft.WindowsAzure.ServiceRuntime;
using Microsoft.WindowsAzure.Storage;

namespace WorkerRole1
{
    public class WorkerRole : RoleEntryPoint
    {
        private readonly CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();
        private readonly ManualResetEvent runCompleteEvent = new ManualResetEvent(false);

        public override void Run()
        {
            Trace.TraceInformation("WorkerRole1 is running");
            try
            {
                for (int i = 0; i < 100; i++)
                {
                    this.RunAsync(this.cancellationTokenSource.Token).Wait();
                    Task.Delay(5000).Wait();
                }
            }
            finally
            {
                this.runCompleteEvent.Set();
            }
        }

        public override bool OnStart()
        {
            //コンカレント接続の最大数を設定します
            ServicePointManager.DefaultConnectionLimit = 12;

            // 構成の変更を処理する方法については、
            // MSDN トピック (https://go.microsoft.com/fwlink/?LinkId=166357) をご覧ください。

            bool result = base.OnStart();

            Trace.TraceInformation("WorkerRole1 has been started");

            return result;
        }

        public override void OnStop()
        {
            Trace.TraceInformation("WorkerRole1 is stopping");

            this.cancellationTokenSource.Cancel();
            this.runCompleteEvent.WaitOne();

            base.OnStop();

            Trace.TraceInformation("WorkerRole1 has stopped");
        }

        public async Task RunAsync(CancellationToken cancellationToken)
        {
            Trace.TraceInformation("Working");
            await Task.Delay(1000 + new Random().Next(4000), cancellationToken);
        }
    }
}
