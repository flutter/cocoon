// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package graphql

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/pkg/errors"
)

type Client struct {
	endpoint   string
	httpClient *http.Client
}

func NewClient(endpoint string) *Client {
	return &Client{
		endpoint:   endpoint,
		httpClient: http.DefaultClient,
	}
}

func (c *Client) GetJson(ctx context.Context, query string) (respRaw []byte, err error) {
	var reqBody bytes.Buffer
	reqBodyObj := struct {
		Query string `json:"query"`
	}{Query: query}
	if err := json.NewEncoder(&reqBody).Encode(reqBodyObj); err != nil {
		return nil, errors.Wrap(err, "encoding body")
	}

	req, err := http.NewRequest(http.MethodPost, c.endpoint, &reqBody)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	req.Header.Set("Accept", "application/json; charset=utf-8")
	req = req.WithContext(ctx)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("graphql received a non-ok status code: %d", resp.StatusCode)
	}

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, resp.Body); err != nil {
		return nil, errors.Wrap(err, "copying body")
	}
	return buf.Bytes(), nil
}

func ParseJson(respRaw []byte, resp interface{}) error {
	respBody := struct {
		Data   interface{}
		Errors []struct {
			Message string
		}
	}{Data: resp}
	if err := json.NewDecoder(bytes.NewBuffer(respRaw)).Decode(&respBody); err != nil {
		return err
	}
	return nil
}
