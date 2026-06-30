import Alpine from "alpinejs";
import CTFd from "./index";
window.Alpine = Alpine;
window.CTFd = CTFd;

const scoreboardUpdateInterval = window.scoreboardUpdateInterval || 300000;
let scoreboardChartRuntime;
const scoreboardSubscribers = new Set();
let scoreboardPoller = null;

async function loadScoreboardChartRuntime() {
  if (!scoreboardChartRuntime) {
    scoreboardChartRuntime = Promise.all([
      import("./utils/graphs/echarts/scoreboard"),
      import("./utils/graphs/echarts"),
    ]).then(([scoreboardModule, echartsModule]) => ({
      getOption: scoreboardModule.getOption,
      embed: echartsModule.embed,
    }));
  }

  return scoreboardChartRuntime;
}

function runScoreboardPolling() {
  if (document.hidden) {
    return;
  }

  scoreboardSubscribers.forEach(callback => callback());
}

function subscribeToScoreboardPolling(callback) {
  scoreboardSubscribers.add(callback);
  callback();

  if (!scoreboardPoller) {
    scoreboardPoller = window.setInterval(runScoreboardPolling, scoreboardUpdateInterval);
  }

  return () => {
    scoreboardSubscribers.delete(callback);

    if (scoreboardSubscribers.size === 0 && scoreboardPoller) {
      window.clearInterval(scoreboardPoller);
      scoreboardPoller = null;
    }
  };
}

Alpine.data("ScoreboardDetail", () => ({
  data: {},
  show: true,
  activeBracket: null,
  unsubscribe: null,

  async update() {
    this.data = await CTFd.pages.scoreboard.getScoreboardDetail(10, this.activeBracket);
    this.show = Object.keys(this.data).length > 0;

    if (!this.show) {
      return;
    }

    const { getOption, embed } = await loadScoreboardChartRuntime();
    let optionMerge = window.scoreboardChartOptions;
    let option = getOption(CTFd.config.userMode, this.data, optionMerge);

    embed(this.$refs.scoregraph, option);
  },

  async init() {
    this.unsubscribe = subscribeToScoreboardPolling(() => this.update());
  },

  destroy() {
    if (this.unsubscribe) {
      this.unsubscribe();
      this.unsubscribe = null;
    }
  },
}));

Alpine.data("ScoreboardList", () => ({
  standings: [],
  brackets: [],
  activeBracket: null,
  unsubscribe: null,

  async update() {
    this.brackets = await CTFd.pages.scoreboard.getBrackets(CTFd.config.userMode);
    this.standings = await CTFd.pages.scoreboard.getScoreboard();
  },

  async init() {
    this.$watch("activeBracket", value => {
      this.$dispatch("bracket-change", value);
    });

    this.unsubscribe = subscribeToScoreboardPolling(() => this.update());
  },

  destroy() {
    if (this.unsubscribe) {
      this.unsubscribe();
      this.unsubscribe = null;
    }
  },
}));

Alpine.start();
