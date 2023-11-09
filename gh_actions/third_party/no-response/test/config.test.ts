import * as core from '@actions/core'

import Config from '../src/config'

describe('Config', () => {
  describe('constructor', () => {
    beforeEach(() => {
      process.env['INPUT_TOKEN'] = '123456789abcdef'
      process.env['GITHUB_REPOSITORY'] = 'test-owner/test-repo'
    })

    it('initializes closeComment to input value', () => {
      process.env['INPUT_CLOSECOMMENT'] = 'foo'
      const config = new Config()

      expect(config.closeComment).toEqual('foo')
    })

    it('initializes closeComment as undefined if "false" is passed in as input', () => {
      process.env['INPUT_CLOSECOMMENT'] = 'false'
      const config = new Config()

      expect(config.closeComment).toBeUndefined()
    })

    it('initializes closeComment with the default otherwise', () => {
      delete process.env.INPUT_CLOSECOMMENT
      const config = new Config()

      expect(config.closeComment).toContain('This issue has been automatically closed')
    })

    it('initializes daysUntilClose with the integer value of the input', () => {
      process.env['INPUT_DAYSUNTILCLOSE'] = '100'
      const config = new Config()

      expect(config.daysUntilClose).toEqual(100)
    })

    it('initializes daysUntilClose with the default otherwise', () => {
      delete process.env.INPUT_DAYSUNTILCLOSE
      const config = new Config()

      expect(config.daysUntilClose).toEqual(14)
    })

    it('initializes repo with the repository information', () => {
      const config = new Config()

      expect(config.repo.owner).toEqual('test-owner')
      expect(config.repo.repo).toEqual('test-repo')
    })

    it('initializes responseRequiredColor with the value of the input', () => {
      process.env['INPUT_RESPONSEREQUIREDCOLOR'] = '000000'
      const config = new Config()

      expect(config.responseRequiredColor).toEqual('000000')
    })

    it('initializes responseRequiredColor with the default otherwise', () => {
      delete process.env.INPUT_RESPONSEREQUIREDCOLOR
      const config = new Config()

      expect(config.responseRequiredColor).toEqual('ffffff')
    })

    it('initializes responseRequiredLabel with the value of the input', () => {
      process.env['INPUT_RESPONSEREQUIREDLABEL'] = 'label-name'
      const config = new Config()

      expect(config.responseRequiredLabel).toEqual('label-name')
    })

    it('initializes responseRequiredLabel with the default otherwise', () => {
      delete process.env.INPUT_RESPONSEREQUIREDLABEL
      const config = new Config()

      expect(config.responseRequiredLabel).toEqual('more-information-needed')
    })

    it('initializes token with the value of the input', () => {
      const config = new Config()

      expect(config.token).toEqual('123456789abcdef')
    })

    it('raises an error if no token is given', () => {
      delete process.env.INPUT_TOKEN

      expect(() => {
        new Config()
      }).toThrow()
    })
  })
})
