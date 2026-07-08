import { describe, expect, test } from 'vitest'
import { schemaId, schemaIds, schemaNames } from './schema'
import type { IntegerEq, TextSearch } from './index'

describe('@cipherstash/eql generated surface', () => {
  test('exports schema metadata for generated domains', () => {
    expect(schemaNames).toContain('integer_eq')
    expect(schemaNames).toContain('text_search')
    expect(schemaId('integer_eq')).toBe('https://schemas.cipherstash.com/eql/v3/integer_eq.json')
    expect(schemaIds.text_search).toBe('https://schemas.cipherstash.com/eql/v3/text_search.json')
  })

  test('generated wire types are usable by TypeScript consumers', () => {
    const integer: IntegerEq = {
      v: 3,
      i: { t: 'users', c: 'age' },
      c: 'mp_base85_ciphertext',
      hm: 'deadbeef',
    }

    const text: TextSearch = {
      v: 3,
      i: { t: 'users', c: 'email' },
      c: 'mp_base85_ciphertext',
      hm: 'deadbeef',
      ob: ['ore'],
      bf: [1, 2, 3],
    }

    expect(integer.v).toBe(3)
    expect(text.bf).toEqual([1, 2, 3])
  })
})
