import { getThemeChartColors } from "../theme-palette";

function getAxisStyle(colors) {
  return {
    axisLine: {
      show: true,
      lineStyle: {
        color: colors.outline,
      },
    },
    axisTick: {
      show: false,
    },
    axisLabel: {
      color: colors.textMuted,
      fontFamily: colors.fontBody,
      fontSize: 11,
    },
    splitLine: {
      lineStyle: {
        color: colors.grid,
        opacity: 1,
      },
    },
  };
}

export function getCartesianChartTheme({ legendData = [], legendBottom = 0 } = {}) {
  const colors = getThemeChartColors();
  const hasLegend = legendData.length > 0;

  return {
    animationDuration: 260,
    animationEasing: "cubicOut",
    textStyle: {
      color: colors.textSoft,
      fontFamily: colors.fontBody,
    },
    tooltip: {
      backgroundColor: colors.surfaceBright,
      borderColor: colors.outline,
      borderWidth: 1,
      textStyle: {
        color: colors.text,
        fontFamily: colors.fontBody,
      },
    },
    legend: hasLegend
      ? {
          type: "scroll",
          orient: "horizontal",
          align: "left",
          bottom: legendBottom,
          data: legendData,
          textStyle: {
            color: colors.textMuted,
            fontFamily: colors.fontBody,
          },
          pageIconColor: colors.primary,
          pageIconInactiveColor: colors.outline,
          pageTextStyle: {
            color: colors.textMuted,
            fontFamily: colors.fontBody,
          },
        }
      : undefined,
    grid: {
      containLabel: true,
      left: 10,
      right: 14,
      top: 18,
      bottom: hasLegend ? 70 : 24,
    },
    xAxis: [
      {
        ...getAxisStyle(colors),
        splitLine: {
          show: false,
        },
      },
    ],
    yAxis: [
      {
        ...getAxisStyle(colors),
      },
    ],
  };
}
