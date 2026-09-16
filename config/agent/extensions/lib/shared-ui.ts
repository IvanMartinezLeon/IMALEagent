/**
 * Shared TUI helpers for IMALE Pi extensions.
 *
 * Extracts the common SelectList dialog pattern (DynamicBorder + Container +
 * SelectList + nav hint) used across IMALE-header.ts and IMALE-preset.ts
 * to eliminate code duplication.
 */

import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { Container, Text, SelectList, type SelectItem } from "@earendil-works/pi-tui";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";

/**
 * Options for {@link showSelectList}.
 */
export interface SelectListOptions {
  /** Dialog title shown above the list. */
  title: string;
  /** Maximum visible items before scrolling. Defaults to 8. */
  maxVisible?: number;
  /** Navigation hint text. Defaults to "↑↓ navigate • enter select • esc cancel". */
  navHint?: string;
}

const DEFAULT_OPTIONS: Pick<Required<SelectListOptions>, "maxVisible" | "navHint"> = {
  maxVisible: 8,
  navHint: "↑↓ navigate • enter select • esc cancel",
};

/**
 * Show a themed select-list dialog and return the chosen value.
 *
 * Built with the same `DynamicBorder` + `Container` + `SelectList` pattern
 * used throughout IMALE extensions.
 *
 * @returns The selected item's `value`, or `null` if cancelled.
 */
export async function showSelectList(
  ctx: ExtensionContext,
  items: SelectItem[],
  options: SelectListOptions,
): Promise<string | null> {
  const { title, maxVisible, navHint } = { ...DEFAULT_OPTIONS, ...options };

  return ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const container = new Container();

    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0));

    const selectList = new SelectList(items, Math.min(items.length, maxVisible), {
      selectedPrefix: (t) => theme.fg("accent", t),
      selectedText: (t) => theme.fg("accent", t),
      description: (t) => theme.fg("muted", t),
      scrollInfo: (t) => theme.fg("dim", t),
      noMatch: (t) => theme.fg("warning", t),
    });

    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(null);

    container.addChild(selectList);
    container.addChild(new Text(theme.fg("dim", navHint), 1, 0));
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

    return {
      render: (w: number) => container.render(w),
      invalidate: () => container.invalidate(),
      handleInput: (data: string) => {
        selectList.handleInput(data);
        tui.requestRender();
      },
    };
  });
}
