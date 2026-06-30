let profileChartRuntime;

export async function loadProfileChartRuntime() {
  if (!profileChartRuntime) {
    profileChartRuntime = Promise.all([
      import("./echarts/userscore"),
      import("./echarts"),
    ]).then(([userscoreModule, echartsModule]) => ({
      getOption: userscoreModule.getOption,
      embed: echartsModule.embed,
    }));
  }

  return profileChartRuntime;
}
