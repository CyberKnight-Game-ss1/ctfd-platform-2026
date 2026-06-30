import { cumulativeSum } from "../../math";
import { mergeObjects } from "../../objects";
import { getCartesianChartTheme } from "./chart-theme";
import { getThemeSeriesColor } from "../theme-palette";
import dayjs from "dayjs";

export function getOption(id, name, solves, awards, optionMerge) {
  const seriesColor = getThemeSeriesColor(0);

  let option = {
    xAxis: [
      {
        type: "category",
        boundaryGap: false,
        data: [],
      },
    ],
    yAxis: [
      {
        type: "value",
      },
    ],
    series: [],
  };

  option = mergeObjects(getCartesianChartTheme(), option);
  option.tooltip = mergeObjects(option.tooltip, {
    trigger: "axis",
    axisPointer: {
      type: "cross",
    },
  });

  const times = [];
  const scores = [];
  const total = solves.concat(awards);

  total.sort((a, b) => {
    return new Date(a.date) - new Date(b.date);
  });

  for (let i = 0; i < total.length; i++) {
    const date = dayjs(total[i].date);
    times.push(date.toDate());
    try {
      scores.push(total[i].challenge.value);
    } catch (e) {
      scores.push(total[i].value);
    }
  }

  times.forEach(time => {
    option.xAxis[0].data.push(time);
  });

  option.series.push({
    name: name,
    type: "line",
    showSymbol: false,
    symbol: "circle",
    symbolSize: 6,
    lineStyle: {
      width: 2.5,
      color: seriesColor,
    },
    areaStyle: {
      color: `${seriesColor}2b`,
    },
    itemStyle: {
      color: seriesColor,
    },
    emphasis: {
      focus: "series",
    },
    data: cumulativeSum(scores),
  });

  if (optionMerge) {
    option = mergeObjects(option, optionMerge);
  }
  return option;
}
