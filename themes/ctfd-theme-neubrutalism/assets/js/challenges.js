import Alpine from "alpinejs";

import CTFd from "./index";

import { Tooltip } from "bootstrap";
import highlight from "./theme/highlight";
import { intl } from "./theme/times";

function addTargetBlank(html) {
  let dom = new DOMParser();
  let view = dom.parseFromString(html, "text/html");
  let links = view.querySelectorAll('a[href*="://"]');
  links.forEach(link => {
    link.setAttribute("target", "_blank");
    link.setAttribute("rel", "noopener noreferrer");
  });
  return view.documentElement.outerHTML;
}

window.Alpine = Alpine;

const CHALLENGE_BOARD_STORAGE_KEY = "ctfd-core-challenge-board";

function loadStoredChallengeBoardState() {
  try {
    return JSON.parse(localStorage.getItem(CHALLENGE_BOARD_STORAGE_KEY)) || {};
  } catch (error) {
    return {};
  }
}

function saveStoredChallengeBoardState(state) {
  localStorage.setItem(CHALLENGE_BOARD_STORAGE_KEY, JSON.stringify(state));
}

Alpine.store("challenge", {
  data: {
    view: "",
  },
});

Alpine.data("Hint", () => ({
  id: null,
  html: null,

  async showHint(event) {
    if (event.target.open) {
      let response = await CTFd.pages.challenge.loadHint(this.id);

      // Hint has some kind of prerequisite or access prevention
      if (response.errors) {
        event.target.open = false;
        CTFd._functions.challenge.displayUnlockError(response);
        return;
      }
      let hint = response.data;
      if (hint.content) {
        this.html = addTargetBlank(hint.html);
      } else {
        let answer = await CTFd.pages.challenge.displayUnlock(this.id);
        if (answer) {
          let unlock = await CTFd.pages.challenge.loadUnlock(this.id);

          if (unlock.success) {
            let response = await CTFd.pages.challenge.loadHint(this.id);
            let hint = response.data;
            this.html = addTargetBlank(hint.html);
          } else {
            event.target.open = false;
            CTFd._functions.challenge.displayUnlockError(unlock);
          }
        } else {
          event.target.open = false;
        }
      }
    }
  },
}));

Alpine.data("Challenge", () => ({
  id: null,
  next_id: null,
  submission: "",
  solves: [],
  submissions: [],
  solution: null,
  response: null,
  share_url: null,
  max_attempts: 0,
  attempts: 0,
  ratingValue: 0,
  selectedRating: 0,
  ratingReview: "",
  ratingSubmitted: false,
  ratingError: "",
  solvesLoaded: false,
  submissionsLoaded: false,
  solutionLoaded: false,
  solvesLoading: false,
  submissionsLoading: false,
  solutionLoading: false,
  labels: {},

  async init() {
    this.labels = {
      ...this.labels,
      ...this.$el.dataset,
    };
    highlight();
  },

  async showSolves() {
    if (this.solvesLoaded || this.solvesLoading) {
      return;
    }
    this.solvesLoading = true;
    try {
      this.solves = await CTFd.pages.challenge.loadSolves(this.id);
      this.solves.forEach(solve => {
        solve.date = intl.format(new Date(solve.date));
        return solve;
      });
      this.solvesLoaded = true;
    } finally {
      this.solvesLoading = false;
    }
  },

  async showSubmissions() {
    if (this.submissionsLoaded || this.submissionsLoading) {
      return;
    }
    this.submissionsLoading = true;
    try {
      let response = await CTFd.pages.users.userSubmissions("me", this.id);
      this.submissions = response.data;
      this.submissions.forEach(s => {
        s.date = intl.format(new Date(s.date));
        return s;
      });
      this.submissionsLoaded = true;
    } finally {
      this.submissionsLoading = false;
    }
  },

  getSolutionId() {
    let data = Alpine.store("challenge").data;
    return data.solution_id;
  },

  getSolutionState() {
    let data = Alpine.store("challenge").data;
    return data.solution_state;
  },

  setSolutionId(solutionId) {
    Alpine.store("challenge").data.solution_id = solutionId;
  },

  async showSolution() {
    if (this.solutionLoaded || this.solutionLoading) {
      return;
    }
    this.solutionLoading = true;
    let solution_id = this.getSolutionId();
    CTFd._functions.challenge.displaySolution = solution => {
      this.solution = solution.html;
      this.solutionLoaded = true;
      this.solutionLoading = false;
    };
    try {
      await CTFd.pages.challenge.displaySolution(solution_id);
      if (!this.solution) {
        this.solutionLoaded = true;
      }
    } finally {
      if (!this.solutionLoaded) {
        this.solutionLoading = false;
      }
    }
  },

  getNextId() {
    let data = Alpine.store("challenge").data;
    return data.next_id;
  },

  async nextChallenge() {
    Alpine.nextTick(() => {
      this.$dispatch("load-challenge", this.getNextId());
    });
  },

  async getShareUrl() {
    let body = {
      type: "solve",
      challenge_id: this.id,
    };
    const response = await CTFd.fetch("/api/v1/shares", {
      method: "POST",
      body: JSON.stringify(body),
    });
    const data = await response.json();
    const url = data["data"]["url"];
    this.share_url = url;
  },

  copyShareUrl() {
    navigator.clipboard.writeText(this.share_url);
    let t = Tooltip.getOrCreateInstance(this.$el);
    t.enable();
    t.show();
    setTimeout(() => {
      t.hide();
      t.disable();
    }, 2000);
  },

  async submitChallenge() {
    this.response = await CTFd.pages.challenge.submitChallenge(
      this.id,
      this.submission,
    );

    // Challenges page might be visible to anonymous users, redirect to login on submit
    if (this.response.data.status === "authentication_required") {
      window.location = `${CTFd.config.urlRoot}/login?next=${CTFd.config.urlRoot}${window.location.pathname}${window.location.hash}`;
      return;
    }

    await this.renderSubmissionResponse();
  },

  async renderSubmissionResponse() {
    if (this.response.data.status === "correct") {
      this.submission = "";
    }

    // Decide whether to check for the solution
    if (this.getSolutionId() == null) {
      if (
        CTFd.pages.challenge.checkSolution(
          this.getSolutionState(),
          Alpine.store("challenge").data,
          this.response.data.status,
        )
      ) {
        let data = await CTFd.pages.challenge.getSolution(this.id);
        this.setSolutionId(data.id);
      }
    }

    // Increment attempts counter
    if (
      this.max_attempts > 0 &&
      this.response.data.status != "already_solved" &&
      this.response.data.status != "ratelimited"
    ) {
      this.attempts += 1;
    }

    // Dispatch load-challenges event to call loadChallenges in the ChallengeBoard
    this.$dispatch("load-challenges");
  },

  async submitRating() {
    this.ratingError = "";
    const response = await CTFd.pages.challenge.submitRating(
      this.id,
      this.selectedRating,
      this.ratingReview,
    );
    if (response.value) {
      this.ratingValue = this.selectedRating;
      this.ratingSubmitted = true;
      this.ratingError = "";
    } else {
      this.ratingError = this.labels.ratingErrorLabel;
    }
  },

  responseStatusLabel() {
    if (!this.response) {
      return "";
    }

    const status = this.response.data.status;
    const labelMap = {
      correct: this.labels.responseCorrectLabel,
      already_solved: this.labels.responseAlreadySolvedLabel,
      incorrect: this.labels.responseIncorrectLabel,
      paused: this.labels.responsePausedLabel,
      ratelimited: this.labels.responseRatelimitedLabel,
    };

    return labelMap[status] || this.response.data.message;
  },

  responseStatusNote() {
    if (!this.response) {
      return "";
    }

    const status = this.response.data.status;
    const noteMap = {
      correct: this.labels.responseCorrectNote,
      already_solved: this.labels.responseAlreadySolvedNote,
      incorrect: this.labels.responseIncorrectNote,
      paused: this.labels.responsePausedNote,
      ratelimited: this.labels.responseRatelimitedNote,
    };

    return noteMap[status] || "";
  },
}));

Alpine.data("ChallengeBoard", () => ({
  loaded: false,
  challenges: [],
  challenge: null,
  activeCategory: null,
  unsolvedOnly: false,
  hotkeysEnabled: true,
  currentChallengeId: null,

  async init() {
    const storedState = loadStoredChallengeBoardState();
    this.activeCategory =
      Object.prototype.hasOwnProperty.call(storedState, "activeCategory")
        ? storedState.activeCategory
        : null;
    this.unsolvedOnly = Boolean(storedState.unsolvedOnly);
    this.currentChallengeId = storedState.currentChallengeId || null;

    this.challenges = await CTFd.pages.challenges.getChallenges();
    this.initializeCategory();
    this.loaded = true;
    window.addEventListener("keydown", this.handleKeydown.bind(this));

    if (window.location.hash) {
      let chalHash = decodeURIComponent(window.location.hash.substring(1));
      let idx = chalHash.lastIndexOf("-");
      if (idx >= 0) {
        let pieces = [chalHash.slice(0, idx), chalHash.slice(idx + 1)];
        let id = pieces[1];
        await this.loadChallenge(id);
      }
    } else if (
      this.currentChallengeId &&
      this.challenges.some(challenge => challenge.id == this.currentChallengeId)
    ) {
      const visibleChallenges = this.getVisibleChallenges();
      const storedVisible = visibleChallenges.some(
        challenge => challenge.id == this.currentChallengeId,
      );

      if (storedVisible) {
        await this.loadChallenge(this.currentChallengeId);
      } else if (visibleChallenges.length > 0) {
        await this.loadChallenge(visibleChallenges[0].id);
      }
    } else if (this.challenges.length > 0) {
      let initialChallenges = this.getVisibleChallenges();
      if (initialChallenges.length > 0) {
        await this.loadChallenge(initialChallenges[0].id);
      }
    }
  },

  initializeCategory() {
    const categories = this.getCategories();

    if (this.activeCategory !== null && !categories.includes(this.activeCategory)) {
      this.activeCategory = null;
    }

    if (
      this.activeCategory !== null &&
      this.getChallenges(this.activeCategory).length === 0
    ) {
      this.activeCategory = null;
    }
  },

  getCategories() {
    const categories = [];

    this.challenges.forEach(challenge => {
      const { category } = challenge;

      if (!categories.includes(category)) {
        categories.push(category);
      }
    });

    try {
      const f = CTFd.config.themeSettings.challenge_category_order;
      if (f) {
        const getSort = new Function(`return (${f})`);
        categories.sort(getSort());
      }
    } catch (error) {
      // Ignore errors with theme category sorting
      console.log("Error running challenge_category_order function");
      console.log(error);
    }

    return categories;
  },

  getChallenges(category) {
    let challenges = this.challenges;

    if (category !== null) {
      challenges = this.challenges.filter(challenge => challenge.category === category);
    }

    try {
      const f = CTFd.config.themeSettings.challenge_order;
      if (f) {
        const getSort = new Function(`return (${f})`);
        challenges.sort(getSort());
      }
    } catch (error) {
      // Ignore errors with theme challenge sorting
      console.log("Error running challenge_order function");
      console.log(error);
    }

    return challenges;
  },

  getVisibleChallenges() {
    let challenges = this.getChallenges(this.activeCategory);

    if (this.unsolvedOnly) {
      challenges = challenges.filter(challenge => !challenge.solved_by_me);
    }

    return challenges;
  },

  getCurrentChallengeIndex() {
    if (!this.challenge) {
      return -1;
    }

    return this.getVisibleChallenges().findIndex(
      challenge => challenge.id === this.challenge.id,
    );
  },

  canGoPrevious() {
    return this.getCurrentChallengeIndex() > 0;
  },

  canGoNext() {
    const currentIndex = this.getCurrentChallengeIndex();
    return currentIndex >= 0 && currentIndex < this.getVisibleChallenges().length - 1;
  },

  persistState() {
    saveStoredChallengeBoardState({
      activeCategory: this.activeCategory,
      unsolvedOnly: this.unsolvedOnly,
      currentChallengeId: this.currentChallengeId,
    });
  },

  shouldIgnoreHotkeys(target) {
    if (!target) {
      return false;
    }

    const tagName = target.tagName?.toLowerCase();
    return (
      target.isContentEditable ||
      ["input", "textarea", "select", "button"].includes(tagName)
    );
  },

  async handleKeydown(event) {
    if (
      !this.loaded ||
      this.shouldIgnoreHotkeys(event.target) ||
      event.metaKey ||
      event.ctrlKey ||
      event.altKey
    ) {
      return;
    }

    if (event.key === "[") {
      event.preventDefault();
      await this.goToPreviousChallenge();
    }

    if (event.key === "]") {
      event.preventDefault();
      await this.goToNextChallenge();
    }
  },

  async loadChallenges() {
    this.challenges = await CTFd.pages.challenges.getChallenges();
    this.initializeCategory();

    if (
      this.challenge &&
      !this.getVisibleChallenges().some(challenge => challenge.id === this.challenge.id)
    ) {
      if (this.getVisibleChallenges().length > 0) {
        await this.loadChallenge(this.getVisibleChallenges()[0].id);
      } else {
        this.clearChallenge();
      }
    }
  },

  async setCategory(category) {
    this.activeCategory = category;
    this.persistState();

    const visibleChallenges = this.getVisibleChallenges();
    const activeStillVisible =
      this.challenge &&
      visibleChallenges.some(challenge => challenge.id === this.challenge.id);

    if (!activeStillVisible && visibleChallenges.length > 0) {
      await this.loadChallenge(visibleChallenges[0].id);
    } else if (!activeStillVisible && visibleChallenges.length === 0) {
      this.clearChallenge();
    }
  },

  async toggleUnsolvedOnly() {
    this.unsolvedOnly = !this.unsolvedOnly;
    this.persistState();

    const visibleChallenges = this.getVisibleChallenges();
    const activeStillVisible =
      this.challenge &&
      visibleChallenges.some(challenge => challenge.id === this.challenge.id);

    if (!activeStillVisible && visibleChallenges.length > 0) {
      await this.loadChallenge(visibleChallenges[0].id);
    } else if (!activeStillVisible && visibleChallenges.length === 0) {
      this.clearChallenge();
    }
  },

  async goToPreviousChallenge() {
    const currentIndex = this.getCurrentChallengeIndex();
    if (currentIndex <= 0) {
      return;
    }

    await this.loadChallenge(this.getVisibleChallenges()[currentIndex - 1].id);
  },

  async goToNextChallenge() {
    const currentIndex = this.getCurrentChallengeIndex();
    const visibleChallenges = this.getVisibleChallenges();

    if (currentIndex < 0 || currentIndex >= visibleChallenges.length - 1) {
      return;
    }

    await this.loadChallenge(visibleChallenges[currentIndex + 1].id);
  },

  async loadChallenge(challengeId) {
    await CTFd.pages.challenge.displayChallenge(challengeId, challenge => {
      challenge.data.view = addTargetBlank(challenge.data.view);
      Alpine.store("challenge").data = challenge.data;
      this.challenge = challenge.data;
      this.currentChallengeId = challenge.data.id;
      if (challenge.data.category && this.activeCategory !== null) {
        this.activeCategory = challenge.data.category;
      }
      this.persistState();

      Alpine.nextTick(() => {
        history.replaceState(null, null, `#${challenge.data.name}-${challengeId}`);
        if (window.innerWidth < 992) {
          this.$refs.challengeDetail.scrollIntoView({
            behavior: "smooth",
            block: "start",
          });
        }
      });
    });
  },

  clearChallenge() {
    this.challenge = null;
    this.currentChallengeId = null;
    Alpine.store("challenge").data = {
      view: "",
    };
    this.persistState();
    history.replaceState(
      null,
      null,
      `${window.location.pathname}${window.location.search}`,
    );
  },
}));

Alpine.start();
