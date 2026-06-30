import Alpine from "alpinejs";
import CTFd from "../index";
import { Modal } from "bootstrap";
import { serializeJSON } from "@ctfdio/ctfd-js/forms";
import { copyToClipboard } from "../utils/clipboard";
import { buildCategoryBreakdown, getPercentage } from "../utils/profile-graphs";
import { loadProfileChartRuntime } from "../utils/graphs/profile-chart-runtime";

window.Alpine = Alpine;
window.CTFd = CTFd;

Alpine.store("teamInvite", {
  token: "",
  errors: [],
});

Alpine.data("TeamEditModal", () => ({
  success: null,
  error: null,
  initial: null,
  errors: [],

  init() {
    this.initial = serializeJSON(this.$el.querySelector("form"));
  },

  async updateProfile() {
    let data = serializeJSON(this.$el, this.initial, true);

    data.fields = [];

    for (const property in data) {
      if (property.match(/fields\[\d+\]/)) {
        let field = {};
        let id = parseInt(property.slice(7, -1));
        field["field_id"] = id;
        field["value"] = data[property];
        data.fields.push(field);
        delete data[property];
      }
    }

    let response = await CTFd.pages.teams.updateTeamSettings(data);
    if (response.success) {
      this.success = true;
      this.error = false;
      setTimeout(() => {
        this.success = null;
        this.error = null;
      }, 3000);
    } else {
      this.success = false;
      this.error = true;
      Object.keys(response.errors).map(error => {
        const error_msg = response.errors[error];
        this.errors.push(error_msg);
      });
    }
  },
}));

Alpine.data("TeamCaptainModal", () => ({
  success: null,
  error: null,
  errors: [],

  async updateCaptain() {
    let data = serializeJSON(this.$el, null, true);
    let response = await CTFd.pages.teams.updateTeamSettings(data);

    if (response.success) {
      window.location.reload();
    } else {
      this.success = false;
      this.error = true;
      Object.keys(response.errors).map(error => {
        const error_msg = response.errors[error];
        this.errors.push(error_msg);
      });
    }
  },
}));

Alpine.data("TeamInviteModal", () => ({
  copy() {
    copyToClipboard(this.$refs.link);
  },
}));

Alpine.data("TeamDisbandModal", () => ({
  errors: [],

  async disbandTeam() {
    let response = await CTFd.pages.teams.disbandTeam();

    if (response.success) {
      window.location.reload();
    } else {
      this.errors = response.errors[""];
    }
  },
}));

Alpine.data("CaptainMenu", () => ({
  captain: false,

  editTeam() {
    this.teamEditModal = new Modal(document.getElementById("team-edit-modal"));
    this.teamEditModal.show();
  },

  chooseCaptain() {
    this.teamCaptainModal = new Modal(document.getElementById("team-captain-modal"));
    this.teamCaptainModal.show();
  },

  async inviteMembers() {
    const response = await CTFd.pages.teams.getInviteToken();

    if (response.success) {
      const code = response.data.code;
      const url = `${window.location.origin}${CTFd.config.urlRoot}/teams/invite?code=${code}`;

      document.querySelector("#team-invite-modal input[name=link]").value = url;
      Alpine.store("teamInvite", {
        token: url,
        errors: [],
      });
      this.teamInviteModal = new Modal(document.getElementById("team-invite-modal"));
      this.teamInviteModal.show();
    } else {
      Alpine.store("teamInvite", {
        token: "",
        errors: Object.values(response.errors).flat(),
      });
      this.teamInviteModal = new Modal(document.getElementById("team-invite-modal"));
      this.teamInviteModal.show();
    }
  },

  disbandTeam() {
    this.teamDisbandModal = new Modal(document.getElementById("team-disband-modal"));
    this.teamDisbandModal.show();
  },
}));

Alpine.data("TeamGraphs", () => ({
  solves: null,
  fails: null,
  awards: null,
  solveCount: 0,
  failCount: 0,
  awardCount: 0,

  getAttemptTotal() {
    return this.solveCount + this.failCount;
  },

  getSolvePercentage() {
    return getPercentage(this.solveCount, this.getAttemptTotal());
  },

  getSolvePercentageValue() {
    return Number(this.getSolvePercentage());
  },

  getFailPercentage() {
    return getPercentage(this.failCount, this.getAttemptTotal());
  },

  getFailPercentageValue() {
    return Number(this.getFailPercentage());
  },

  getCategoryBreakdown() {
    return buildCategoryBreakdown(this.solves.data);
  },

  async init() {
    this.solves = await CTFd.pages.teams.teamSolves("me");
    this.fails = await CTFd.pages.teams.teamFails("me");
    this.awards = await CTFd.pages.teams.teamAwards("me");

    this.solveCount = this.solves.meta.count;
    this.failCount = this.fails.meta.count;
    this.awardCount = this.awards.meta.count;

    if (this.$refs.scoregraph) {
      const { getOption, embed } = await loadProfileChartRuntime();
      let optionMerge = window.teamScoreGraphChartOptions;

      embed(
        this.$refs.scoregraph,
        getOption(
          CTFd.team.id,
          CTFd.team.name,
          this.solves.data,
          this.awards.data,
          optionMerge,
        ),
      );
    }
  },
}));

Alpine.start();
