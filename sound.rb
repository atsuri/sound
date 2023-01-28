require 'strscan'
class Sound
    def initialize
        unless @file = ARGV[0]
            raise Exception, "ファイルがありません。"
        end

        # 予約後
        @keywords = {
            '+' => :add,
            '-' => :sub,
            '*' => :mul,
            '/' => :div,
            '(' => :left_parn,
            ')' => :right_parn,
            '=' => :equal,
            # '==' => :d_equal,
            '<' => :small,
            # '<=' => :s_equal,
            '>' => :big,
            # '>=' => :b_equal,
            'para' => :para,
            'real' => :real,
            'open' => :open,
            'close' => :close,
            'keepon' => :keepon,
            'visu' => :visu,
            'get' => :get,
            'true' => :true,
            'false' => :false
        }

        # 変数　@variable[変数] = 数値
        @variable = {}

        read = File.read(@file)
        @scanner = StringScanner.new(read)
        p sentences() # Sound
    end

    def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub
            result = [token, result, term()]
            token = get_token()
        end
        unget_token()
        return result
    end

    def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            token = get_token()
        end

        unget_token()
        return result
    end

    def factor()
        token = get_token()
        if token.is_a?(Numeric) then# 数字だったら
            result = token
        elsif token == :get then
            result = token
        elsif token.is_a?(String) then# 数字だったら
            result = [:variable, token]
        elsif token == :left_parn then#（ だったら
            result = expression()
            token = get_token() # 閉じカッコを取り除く(使用しない)
            if token != :right_parn then# ) なかったら
                raise Exception, "構文エラー"
            else
                # p token
            end
        end

        return result
    end

    def eval(exp)
        if exp.instance_of?(Array)
            case exp[0]
            when :add
                begin
                    return eval(exp[1]) + eval(exp[2])
                rescue => e
                    puts "加算でエラー：#{e.message}"
                end
            when :sub
                begin
                    return eval(exp[1]) - eval(exp[2])
                rescue => e
                    puts "減算でエラー：#{e.message}"
                end
            when :mul
                begin
                    return eval(exp[1]) * eval(exp[2])
                rescue => e
                    puts "乗算でエラー：#{e.message}"
                end
            when :div
                begin
                    return eval(exp[1]) / eval(exp[2])
                rescue => e
                    puts "除算_でエラー：#{e.message}"
                end
            end
        else
            return exp
        end
    end

    def parse()
        expression()
    end

    # ソースコードの先頭から、次のtokenを一つ切り出して返す。
    def get_token()
        if scan = @scanner.scan(/\A*([0-9.]+)/) then #数値だったら
            # p "数値：#{scan}"
            return scan.to_f
        elsif scan = @scanner.scan(/\A*(#{@keywords.keys.map{|t| Regexp.escape(t)}.join('|')})/) then # 予約語だったら
            # p "予約語：#{@keywords[scan]}"
            return @keywords[scan]
        elsif scan = @scanner.scan(/\A[a-zA-Z]+/) then #英字だったら（変数名）
            # p "変数：#{scan}"
            return scan
        elsif scan = @scanner.scan(/\s/) then #改行文字
            scan = get_token()
            # p "改行の次：#{scan}"
            return scan
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token()
        if !(@scanner.eos?) then
            @scanner.unscan
        end
    end

    # 文列
    def sentences()
        unless s = sentence()
            raise Exception, "あるべき文が見つからない"
        end
        
        result = [:block, s]
        while s = sentence()
            result << s
        end
        return result
    end

    def sentence()
        # 代入文、if文、while文、print文
        if token = para() then
            return token
        elsif token = keepon() then
            return token
        elsif token = visu() then
            return token
        elsif token = assignment() then
            return token
        end
    end

    def assignment()
        result = [:assignment]
        token = get_token()
        unless token.instance_of?(String)
            unget_token()
            return nil
        end

        result << [:variable, token]
        unless get_token() == :equal
            raise Exception, "イコールがない"
        end
        unless token = expression()
            raise Exception, "式がない"
        end
        result << token
        return result
    end

    # 出力
    def visu()
        unless get_token() == :visu
            unget_token()
            return nil
        end
        result = [:visu]

        token = get_token()
        if token == :get then
            result << token
        elsif token.instance_of?(String) then
            result << [:variable, token]
        elsif token.instance_of?(Numeric) then
            unget_token()
            unless token = expression()
                raise Exception, "visu_式がない"
            end
            result << token
        else
            raise Exception, "visu_変数または数値がない"
        end

        return result
    end

    # for文
    def keepon
        # for
        unless get_token() == :keepon
            unget_token()
            return nil
        end
        result = [:keepon]

        # 条件式
        unless token = conditions()
            raise Exception, "keepon_条件式がない"
        end
        result << token

        # do
        unless get_token() == :open
            raise Exception, "keepon_openがない"
        end

        # 式を取り出す
        unless token = sentence()
            raise Exception, "keepon_文がない"
        end
        result << token
        # 二文以上あった時
        while token = sentence() do
            result << token
        end

        # end
        unless get_token() == :close
            raise Exception, "keepon_closeがない"
            # closeの後に改行するか、別の文が続かないとエラーになってしまう。
        end

        return result
    end

    # if文
    def para()
        # if
        unless get_token() == :para
            unget_token()
            return nil
        end
        result = [:para]
        # 条件式
        unless token = conditions()
            raise Exception, "para_条件式がない"
        end
        result << token
        # then
        unless get_token() == :open
            raise Exception, "para_openがない"
        end

        
        # 式を取り出す
        unless token = sentence()
            raise Exception, "para_文がない"
        end
        result << token
        # 二文以上あった時
        while token = sentence() do
            result << token
        end

        # else
        if get_token() == :real then
            result2 = [:real]
            # 式を取り出す
            unless token = sentence()
                raise Exception, "para_real_文がない"
            end
            result2 << token
            # 二文以上あった時
            while token = sentence() do
                result2 << token
            end
        else
            unget_token()
        end

        # end
        unless get_token() == :close
            raise Exception, "para_closeがない"
            # closeの後に改行するか、別の文が続かないとエラーになってしまう。
        end
        
        result = result + [result2] if result2
        return result
    end

    def conditions()
        result = [:conditions]
        token = get_token() #変数
        unless token.instance_of?(String)
            raise Exception, "conditions_変数がない"
        end
        result << [:variable, token]

        is_d_equal = false
        token = get_token()
        case token
        when :small, :big
            token2 = get_token()
            if token2 == :equal then
                token = :b_equal if token == :big
                token = :s_equal if token == :small
                result << [:operator, token]
            else
                unget_token()
                result << [:operator, token]
            end
        when :equal
            is_d_equal = true
            token2 = get_token()
            if token2 == :equal then
                token = :d_equal
                result << [:operator, token]
            else
                raise Exception, "conditions_「=」→「==」にする"
            end
        else
            raise Exception, "conditions_演算子がない"
        end

        token = get_token()
        if token == :true then
            raise Exception, "#{@file}プログラムミス" if !is_d_equal
            result << token
        elsif token == :false then
            raise Exception, "#{@file}プログラムミス" if !is_d_equal
            result << token
        elsif token.instance_of?(String) then
            result << [:variable, token]
        elsif token.instance_of?(Numeric) then
            unget_token()
            unless token = expression()
                raise Exception, "conditions_式がない"
            end
            result << token
        else
            raise Exception, "conditions_変数または数値がない"
        end

        return result
    end

    # 入力
    # def get()
    #     unless get_token() == :get
    #         unget_token()
    #         return nil
    #     end
    #     result = [:get]
    #     # これは実装時に考えること。
    #     # unless get = get_token()
    #     #     raise Exception, "get_入力がない、または、英数字でない"
    #     #     # 変数は英字のみだが、「a1」「aa1a」のようなものだと「a」「aa」と判断される。エラー実装できていない。
    #     # end
    #     # result << get
    #     return result
    # end
end


Sound.new