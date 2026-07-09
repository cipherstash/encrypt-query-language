import { describe, expect, test } from 'vitest'
import { schemaId, schemaIds, schemaNames } from './schema'
import type { IntegerEq, TextSearch, TextSearchOre } from './index'

describe('@cipherstash/eql generated surface', () => {
  test('exports schema metadata for generated domains', () => {
    expect(schemaNames).toContain('integer_eq')
    expect(schemaNames).toContain('text_search')
    expect(schemaNames).toContain('text_search_ore')
    expect(schemaId('integer_eq')).toBe('https://schemas.cipherstash.com/eql/v3/integer_eq.json')
    expect(schemaIds.text_search).toBe('https://schemas.cipherstash.com/eql/v3/text_search.json')
    expect(schemaIds.text_search_ore).toBe(
      'https://schemas.cipherstash.com/eql/v3/text_search_ore.json',
    )
  })

  test('generated wire types are usable by TypeScript consumers', () => {
    const integer: IntegerEq = {
      v: 3,
      i: { t: 'users', c: 'age' },
      c: 'mp_base85_ciphertext',
      hm: 'deadbeef',
    }

    // `text_search` is OPE-backed: its ordering term is `op`.
    const text: TextSearch = {
      v: 3,
      i: { t: 'users', c: 'email' },
      c: 'mp_base85_ciphertext',
      hm: 'deadbeef',
      op: '00ffab',
      bf: [1, 2, 3],
    }

    // `text_search_ore` is the block-ORE sibling: its ordering term is `ob`.
    const textOre: TextSearchOre = {
      v: 3,
      i: { t: 'users', c: 'email' },
      c: 'mp_base85_ciphertext',
      hm: 'deadbeef',
      ob: ['ore'],
      bf: [1, 2, 3],
    }

    expect(integer.v).toBe(3)
    expect(text.bf).toEqual([1, 2, 3])
    expect(textOre.ob).toEqual(['ore'])
  })
})
