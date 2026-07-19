import { describe, expect, test } from 'vitest'
import { schemaId, schemaIds, schemaNames } from './schema'
import type {
  IntegerEq,
  SteVecDocument,
  SteVecQuery,
  TextSearch,
  TextSearchOre,
} from './index'

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

    // The term-less arm must remain composable with each entry's required
    // fields. `Record<string, never>` here would turn `s`/`c` into `never`.
    const steVec: SteVecDocument = {
      v: 3,
      k: 'sv',
      i: { t: 'users', c: 'profile' },
      h: 'mp_base85_key_header',
      sv: [{ s: 'selector', c: 'entry_ciphertext' }],
    }
    const exactValue: SteVecQuery = { sv: [{ s: 'value_selector' }] }
    const ordered: SteVecQuery = {
      sv: [{ s: 'path_selector', op: 'ope_term' }],
    }

    expect(integer.v).toBe(3)
    expect(text.bf).toEqual([1, 2, 3])
    expect(textOre.ob).toEqual(['ore'])
    expect(steVec.sv[0].s).toBe('selector')
    expect(exactValue.sv[0].s).toBe('value_selector')
    expect(ordered.sv[0].op).toBe('ope_term')
  })
})
